#!/usr/bin/env bash
set -Eeuo pipefail

URL="${PRODUCTION_WEB_URL:-${1:-}}"
if [[ -z "${URL}" ]]; then
  echo "Usage: PRODUCTION_WEB_URL=https://example.com $0" >&2
  exit 2
fi

headers="$(curl --fail-with-body -sSI --max-time 20 "${URL}")"
body="$(curl --fail-with-body -sSL --max-time 20 "${URL}")"
for marker in 'strict-transport-security:' 'x-content-type-options:' 'referrer-policy:'; do
  if ! grep -qi "^${marker}" <<<"${headers}"; then
    echo "Missing response header: ${marker}" >&2
    exit 1
  fi
done
if ! grep -q '<html' <<<"${body}"; then
  echo 'Production response does not look like an HTML document' >&2
  exit 1
fi
printf 'Production smoke check passed for %s\n' "${URL}"
