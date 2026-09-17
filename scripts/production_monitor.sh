#!/usr/bin/env bash
set -Eeuo pipefail

URL="${PRODUCTION_WEB_URL:-${1:-}}"
if [[ -z "${URL}" ]]; then
  echo "Usage: PRODUCTION_WEB_URL=https://example.com $0" >&2
  exit 2
fi

OUT_DIR="${MONITOR_OUTPUT_DIR:-monitoring-output}"
mkdir -p "${OUT_DIR}"
SUMMARY_FILE="${OUT_DIR}/summary.md"
JSON_FILE="${OUT_DIR}/summary.json"
STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
FAILURES=0

printf '# 2FIT Mall Production Monitoring\n\n' > "${SUMMARY_FILE}"
printf -- '- **Checked at (UTC):** `%s`\n- **Base URL:** `%s`\n\n' "${STARTED_AT}" "${URL}" >> "${SUMMARY_FILE}"
printf '| Check | Result | Detail |\n|---|---|---|\n' >> "${SUMMARY_FILE}"

check() {
  local name="$1" result="$2" detail="$3"
  printf '| %s | %s | %s |\n' "$name" "$result" "$detail" >> "${SUMMARY_FILE}"
  [[ "$result" == "PASS" ]] || FAILURES=$((FAILURES + 1))
}

headers_file="${OUT_DIR}/headers.txt"
body_file="${OUT_DIR}/index.html"
metrics_file="${OUT_DIR}/curl-metrics.txt"
if curl --fail-with-body -sSIL --max-time 20 -o "${headers_file}" -w 'http_code=%{http_code}\ntime_total_ms=%{time_total}\ntls_verify=%{ssl_verify_result}\nremote_ip=%{remote_ip}\n' "${URL}" > "${metrics_file}"; then
  code="$(awk -F= '$1=="http_code"{print $2}' "${metrics_file}")"
  total="$(awk -F= '$1=="time_total_ms"{printf "%.0f", $2 * 1000}' "${metrics_file}")"
  check 'HTTPS response' "$([[ "$code" == 2* || "$code" == 3* ]] && echo PASS || echo FAIL)" "HTTP ${code}, ${total} ms"
  if [[ "${total}" =~ ^[0-9]+$ ]] && (( total > 3000 )); then
    check 'Response latency' 'FAIL' "${total} ms exceeds 3000 ms"
  else
    check 'Response latency' 'PASS' "${total} ms"
  fi
else
  check 'HTTPS response' 'FAIL' 'Request failed or timed out'
  check 'Response latency' 'FAIL' 'Unavailable'
fi

if curl --fail-with-body -sSL --max-time 20 -o "${body_file}" "${URL}" && grep -qi '<html' "${body_file}"; then
  check 'HTML document' 'PASS' 'HTML response received'
else
  check 'HTML document' 'FAIL' 'HTML response missing'
fi

for marker in 'strict-transport-security:' 'x-content-type-options:' 'x-frame-options:' 'referrer-policy:' 'permissions-policy:'; do
  label="${marker%:}"
  if grep -qi "^${marker}" "${headers_file}"; then
    check "Header ${label}" 'PASS' 'Present'
  else
    check "Header ${label}" 'FAIL' 'Missing'
  fi
done

if command -v openssl >/dev/null 2>&1 && [[ "${URL}" =~ ^https://([^/]+) ]]; then
  host="${BASH_REMATCH[1]}"
  expiry="$(timeout 15 openssl s_client -servername "${host}" -connect "${host}:443" </dev/null 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2 || true)"
  if [[ -n "${expiry}" ]]; then
    expiry_epoch="$(date -d "${expiry}" +%s)"
    days_left=$(( (expiry_epoch - $(date +%s)) / 86400 ))
    if (( days_left < 14 )); then check 'TLS certificate' 'FAIL' "${days_left} days remaining"; else check 'TLS certificate' 'PASS' "${days_left} days remaining"; fi
  else
    check 'TLS certificate' 'FAIL' 'Certificate expiry unavailable'
  fi
fi

cat > "${JSON_FILE}" <<JSON
{
  "checkedAt": "${STARTED_AT}",
  "url": "${URL}",
  "failures": ${FAILURES},
  "status": "$( (( FAILURES == 0 )) && echo healthy || echo degraded )"
}
JSON
printf '\n## Overall status\n\n**%s** (%d failing checks)\n' "$( (( FAILURES == 0 )) && echo HEALTHY || echo DEGRADED )" "${FAILURES}" >> "${SUMMARY_FILE}"
cat "${SUMMARY_FILE}"
if (( FAILURES > 0 )); then exit 1; fi
