#!/usr/bin/env bash
set -Eeuo pipefail

mode="${1:-candidate}"
case "$mode" in
  candidate|rollback) ;;
  *)
    echo "Unknown smoke-test mode: $mode" >&2
    exit 2
    ;;
esac

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_ENV_FILE="${DEPLOY_ENV_FILE:?DEPLOY_ENV_FILE is required}" bash "$script_dir/verify.sh"
echo "$mode DB stack smoke test passed."
