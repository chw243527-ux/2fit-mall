#!/usr/bin/env bash
# 2FIT Mall pre-release security gate.
# Read-only by default. It never contacts Firebase or changes production data.
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Scheduled runs may not load interactive shell startup files.
export PATH="$HOME/.local/bin:$HOME/.nvm/versions/node/v22.13.0/bin:$PATH"
SKIP_DEPENDENCY_AUDIT=0
STRICT=0
FAILURES=0
WARNINGS=0

usage() {
  cat <<'EOF'
Usage: security/security_audit.sh [options]

Options:
  --strict                  Fail when optional local tools (Flutter/Firebase) are missing.
  --skip-dependency-audit   Skip npm audit and pub outdated checks.
  -h, --help                Show this help.

The default run is read-only. It checks repository secrets, Firebase rules,
Cloud Functions syntax/security markers, dependency lockfiles, and optional
Flutter/Firebase validation when those CLIs are installed.
EOF
}

while (($#)); do
  case "$1" in
    --strict) STRICT=1 ;;
    --skip-dependency-audit) SKIP_DEPENDENCY_AUDIT=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

cd "$ROOT_DIR"

pass() { printf 'PASS  %s\n' "$1"; }
warn() { WARNINGS=$((WARNINGS + 1)); printf 'WARN  %s\n' "$1"; }
fail() { FAILURES=$((FAILURES + 1)); printf 'FAIL  %s\n' "$1"; }
section() { printf '\n== %s ==\n' "$1"; }

section "Required security files"
for file in firestore.rules storage.rules firebase.json functions/index.js functions/package.json functions/package-lock.json pubspec.yaml pubspec.lock; do
  if [[ -f "$file" ]]; then pass "$file exists"; else fail "$file is missing"; fi
done

section "Tracked secret scan"
# High-confidence patterns only. Public Firebase web config/client IDs are not secrets.
# Exclude lockfiles and generated/build content to keep the gate actionable.
secret_pattern="(BEGIN (RSA|EC|OPENSSH|PRIVATE) KEY|private_key[[:space:]]*[:=]|(TOSS|SOLAPI|RESEND|NAVER|STRIPE|PAYMENT)[_-]?(SECRET|API_KEY)[[:space:]]*=[[:space:]]*[\\\"'][^\\\"']+[\\\"']|sk_(live|test)_[A-Za-z0-9]+)"
tracked_secret_hits="$(git ls-files -z -- ':!:*.lock' ':!:build/**' ':!:*.png' ':!:*.jpg' ':!:*.jpeg' ':!:*.gif' ':!:*.webp' ':!:security/security_audit.sh' | xargs -0 -r grep -IEnH "$secret_pattern" 2>/dev/null || true)"
if [[ -n "$tracked_secret_hits" ]]; then
  fail "high-confidence secret-like value found in tracked source (details suppressed)"
else
  pass "no high-confidence secret-like value found in tracked source"
fi

# Ensure the known server-only secrets remain references, not literal values.
if grep -Eq 'defineSecret.*(TOSS_SECRET_KEY|SOLAPI_API_KEY|SOLAPI_API_SECRET|RESEND_API_KEY|NAVER_CLIENT_SECRET)' functions/index.js; then
  pass "server-only payment/messaging secrets use Secret Manager references"
else
  fail "server-only secret declaration does not match expected Secret Manager pattern"
fi

section "Firebase rules hardening"
for rules in firestore.rules storage.rules; do
  if grep -q "request.auth.token.get('admin', false) == true" "$rules"; then
    pass "$rules verifies admin custom claim with secure default"
  else
    fail "$rules does not contain secure admin custom-claim check"
  fi
done

if grep -Eq 'match /orders/\{orderId\}' firestore.rules \
  && grep -Eq 'allow create: if isAdmin\(\)' firestore.rules \
  && grep -Eq 'resource\.data\.userId == request\.auth\.uid' firestore.rules; then
  pass "orders are owner/admin scoped and client order creation is restricted"
else
  fail "orders rules do not show expected owner/admin boundary"
fi

if grep -Eq 'request\.resource\.size <= 10 \* 1024 \* 1024' storage.rules \
  && grep -Eq 'request\.resource\.contentType in' storage.rules; then
  pass "Storage uploads enforce size and MIME allowlist"
else
  fail "Storage upload size/MIME validation is missing"
fi

if grep -Eq 'match /group_orders/\{allPaths=\*\*\}' storage.rules \
  && grep -Eq 'allow read, write: if false' storage.rules; then
  pass "legacy ownerless group-order storage path is denied"
else
  fail "legacy ownerless group-order storage path is not explicitly denied"
fi

section "Cloud Functions source checks"
if command -v node >/dev/null 2>&1; then
  if node --check functions/index.js; then pass "functions/index.js parses successfully"; else fail "functions/index.js syntax check failed"; fi
else
  if [[ "$STRICT" == 1 ]]; then fail "node is required in --strict mode"; else warn "node not installed; skipped Functions syntax check"; fi
fi

for marker in 'requireAdmin(req, res)' 'TOSS_SECRET_KEY' 'payment_intents' 'expiresAt' 'totalAmount'; do
  if grep -q "$marker" functions/index.js; then pass "Functions contains expected security marker: $marker"; else fail "Functions missing expected security marker: $marker"; fi
done

section "Client error logging"
client_raw_errors="$(rg -n -F '$e' lib --glob '*.dart' 2>/dev/null | grep -E 'debugPrint|onError|_toast|_snack|_showSnack|error:' || true)"
client_raw_errors+="$(rg -n -F 'e.toString()' lib --glob '*.dart' 2>/dev/null | grep -E 'debugPrint|onError|_toast|_snack|_showSnack|error:' || true)"
client_raw_errors+="$(rg -n 'debugPrint\([^\n]*response\.body' lib --glob '*.dart' 2>/dev/null || true)"
if [[ -n "$client_raw_errors" ]]; then
  fail "client code contains raw exception or provider-response logging"
else
  pass "client error logs do not expose raw exception/provider-response text"
fi

if grep -Eq 'res\.status\(5[0-9]{2}\).*String\((e|error)' functions/index.js; then
  fail "an HTTP function may expose raw exception text"
else
  pass "HTTP error responses use generalized messages"
fi

section "Dependency and lockfile checks"
if [[ "$SKIP_DEPENDENCY_AUDIT" == 1 ]]; then
  warn "dependency audit skipped by request"
else
  if command -v npm >/dev/null 2>&1; then
    if [[ -d functions/node_modules ]]; then
      if (cd functions && npm audit --omit=dev --audit-level=high); then pass "Functions npm audit has no high/critical findings"; else fail "Functions npm audit found high/critical findings or could not complete"; fi
    else
      warn "functions/node_modules is absent; run npm ci in CI before npm audit"
    fi
  else
    if [[ "$STRICT" == 1 ]]; then fail "npm is required in --strict mode"; else warn "npm not installed; skipped Functions dependency audit"; fi
  fi

  if command -v flutter >/dev/null 2>&1 && [[ -f pubspec.lock ]]; then
    if flutter pub outdated --no-prereleases >/dev/null; then pass "Flutter dependency metadata is readable"; else warn "flutter pub outdated reported a problem; review separately"; fi
  else
    if [[ "$STRICT" == 1 ]]; then fail "Flutter is required in --strict mode"; else warn "Flutter not installed; skipped Flutter dependency check"; fi
  fi
fi

section "Optional project validation"
if command -v flutter >/dev/null 2>&1; then
  if flutter analyze --no-fatal-infos --no-fatal-warnings; then pass "Flutter static analysis passed"; else fail "Flutter static analysis failed"; fi
else
  if [[ "$STRICT" == 1 ]]; then fail "Flutter is required in --strict mode"; else warn "Flutter not installed; skipped Flutter analysis"; fi
fi

if command -v firebase >/dev/null 2>&1; then
  if firebase firestore:rules --help >/dev/null 2>&1; then pass "Firebase CLI is available for emulator/rules verification"; else warn "Firebase CLI is present but rules command is unavailable"; fi
else
  if [[ "$STRICT" == 1 ]]; then fail "Firebase CLI is required in --strict mode"; else warn "Firebase CLI not installed; skipped emulator rules validation"; fi
fi

section "Result"
printf 'Failures: %d | Warnings: %d\n' "$FAILURES" "$WARNINGS"
if ((FAILURES > 0)); then
  echo "Security gate: BLOCKED"
  exit 1
fi
if ((STRICT == 1 && WARNINGS > 0)); then
  echo "Security gate: BLOCKED (strict warnings)"
  exit 1
fi
echo "Security gate: PASSED"
