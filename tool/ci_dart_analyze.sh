#!/usr/bin/env bash
set -euo pipefail

log_file="$(mktemp)"
trap 'rm -f "$log_file"' EXIT

set +e
dart analyze --format machine >"$log_file" 2>&1
analyze_status=$?
set -e

cat "$log_file"

# Dart analyzer의 모든 진단(ERROR/WARNING/INFO/HINT)을 실패로 처리합니다.
diagnostic_count="$(awk -F'|' '$1 == "ERROR" || $1 == "WARNING" || $1 == "INFO" || $1 == "HINT" { count++ } END { print count + 0 }' "$log_file")"
if [[ "$analyze_status" -ne 0 || "$diagnostic_count" -ne 0 ]]; then
  echo "Dart analysis gate failed: ${diagnostic_count} diagnostic(s), exit=${analyze_status}." >&2
  exit 1
fi

echo "Dart analysis gate passed: 0 diagnostics."
