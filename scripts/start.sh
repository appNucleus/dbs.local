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

main_services=(
  postgres
  pgadmin
  redis
  redisinsight
  neo4j
  minio
  dashboard
)

up_args=(
  up
  --detach
  --remove-orphans
)

if [[ "$wait_for_health" == "true" ]]; then
  up_args+=(--wait --wait-timeout "${COMPOSE_WAIT_TIMEOUT:-300}")
fi

compose "${up_args[@]}" "${main_services[@]}"

if [[ "${RUN_MINIO_INIT:-true}" == "true" ]]; then
  minio_init_container="${MINIO_INIT_CONTAINER_NAME:-db-minio-init}"

  echo "Running MinIO one-shot initialization..."

  compose rm --force --stop minio-init >/dev/null 2>&1 || true
  compose up --detach --no-deps minio-init

  minio_init_exit_code="$(docker wait "$minio_init_container")"

  if [[ "$minio_init_exit_code" != "0" ]]; then
    echo "MinIO initialization failed with exit code: $minio_init_exit_code" >&2
    docker logs "$minio_init_container" >&2 || true
    exit "$minio_init_exit_code"
  fi

  docker logs "$minio_init_container" || true
  compose rm --force --stop minio-init >/dev/null 2>&1 || true

  echo "MinIO one-shot initialization completed successfully."
fi

echo "Started. Run: DEPLOY_ENV_FILE='$runtime_env_file' ./scripts/status.sh && DEPLOY_ENV_FILE='$runtime_env_file' ./scripts/verify.sh"