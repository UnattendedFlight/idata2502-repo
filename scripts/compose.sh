#!/usr/bin/env bash
set -eu
set -a
if [ -n "${TAG:-}" ]; then
  PULL_POLICY=always
else
  eval "$("$(dirname "$0")/build_env.sh")"
fi
set +a
exec docker compose "$@"
