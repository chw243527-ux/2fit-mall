#!/usr/bin/env bash
set -euo pipefail

mapfile -d '' dart_files < <(
  find . \
    -type f \
    -name '*.dart' \
    -not -path './.dart_tool/*' \
    -not -path './build/*' \
    -print0
)

if [[ "${#dart_files[@]}" -eq 0 ]]; then
  echo 'Dart format check failed: no Dart files found.' >&2
  exit 1
fi

# 파일을 수정하지 않고 포맷 불일치가 있으면 실패합니다.
dart format --output=none --set-exit-if-changed "${dart_files[@]}"
echo "Dart format check passed: ${#dart_files[@]} file(s)."
