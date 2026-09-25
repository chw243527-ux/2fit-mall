#!/usr/bin/env bash
set -euo pipefail

failed=0

# 운영 코드에서 직접 print를 사용하지 않습니다. 테스트/도구 출력은 허용합니다.
# grep은 GitHub runner와 로컬 환경에 기본 제공되므로 별도 패키지 설치가 필요 없습니다.
if matches="$(grep -RInE --include='*.dart' '^\s*print\s*\(' lib 2>/dev/null || true)"; then
  if [[ -n "$matches" ]]; then
    echo 'Custom lint: direct print() calls are not allowed in lib/.' >&2
    printf '%s\n' "$matches" >&2
    failed=1
  fi
fi

# 원시 예외 문자열을 사용자-facing 코드에 노출하지 않습니다.
if matches="$(grep -RInE --include='*.dart' --include='*.js' \
  --exclude-dir=node_modules \
  '\bString[[:space:]]*\([[:space:]]*(e|error|exception)[[:space:]]*\)' \
  lib functions 2>/dev/null || true)"; then
  if [[ -n "$matches" ]]; then
    echo 'Custom lint: raw exception string conversion is not allowed in production code.' >&2
    printf '%s\n' "$matches" >&2
    failed=1
  fi
fi

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo 'Custom lint passed: project safety rules are satisfied.'
