#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

wait_for_health=false
if [[ "${1:-}" == "--wait" ]]; then
  wait_for_health=true
elif [[ -n "${1:-}" ]]; then
  echo "Usage: $0 [--wait]" >&2
  exit 2
fi

ensure_runtime_env_file
load_runtime_env

bash "$repo_root/scripts/generate-pgadmin-config.sh"

mkdir -p \
  "$(repo_path "${POSTGRES_INITDB_DIR:-./initdb/postgres}")" \
  "$(repo_path "${DASHBOARD_WWW_DIR:-./www}")" \
  "$(repo_path "${LOCAL_BACKUP_DIR:-./backups}")"

cd "$repo_root"

up_args=(
  up
  --detach
  --remove-orphans
)

if [[ "$wait_for_health" == "true" ]]; then
  up_args+=(--wait --wait-timeout "${COMPOSE_WAIT_TIMEOUT:-180}")
fi

compose "${up_args[@]}"

echo "Started. Run: DEPLOY_ENV_FILE='$runtime_env_file' ./scripts/status.sh && DEPLOY_ENV_FILE='$runtime_env_file' ./scripts/verify.sh"
