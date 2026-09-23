#!/usr/bin/env bash
set -euo pipefail

log_file="$(mktemp)"
trap 'rm -f "$log_file"' EXIT

set +e
dart fix --dry-run >"$log_file" 2>&1
fix_status=$?
set -e

cat "$log_file"

if [[ "$fix_status" -ne 0 ]]; then
  echo "dart fix dry run failed with exit=${fix_status}." >&2
  exit 1
fi

if ! grep -qx 'Nothing to fix!' "$log_file"; then
  echo 'dart fix found unapplied fixes. Run: dart fix --apply' >&2
  exit 1
fi

echo 'dart fix check passed: no unapplied fixes.'
