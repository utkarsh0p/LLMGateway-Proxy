#!/usr/bin/env bash
# Start the proxy.
#
# Credentials arrive as environment variables, and a key pasted into a hosting
# dashboard very easily picks up a trailing newline. LiteLLM passes the value
# straight into an outbound header, where aiohttp refuses to serialise it:
#
#   ValueError: Forbidden control character detected in headers.
#
# That surfaces as a 500 on every single request, with nothing ever sent to
# Google, so strip whitespace here rather than trusting the environment.
# No API key or bearer token contains whitespace, so this cannot corrupt a
# good value.
set -euo pipefail

for var in GOOGLE_API_KEY LITELLM_MASTER_KEY; do
  clean="$(printf %s "${!var:-}" | tr -d '[:space:]')"
  if [[ -z "$clean" ]]; then
    echo "start.sh: $var is empty or unset" >&2
    exit 1
  fi
  if [[ "$clean" != "${!var}" ]]; then
    echo "start.sh: stripped whitespace from $var" >&2
  fi
  export "$var=$clean"
done

exec litellm --config config.yaml --host 0.0.0.0 --port "${PORT:-4000}"
