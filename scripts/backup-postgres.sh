#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

ensure_runtime_env_file
load_runtime_env

POSTGRES_CONTAINER_NAME="${POSTGRES_CONTAINER_NAME:-db-postgres}"
POSTGRES_DB="${POSTGRES_DB:-langgraph_app}"
POSTGRES_USER="${POSTGRES_USER:-langgraph_user}"
POSTGRES_BACKUP_DIR="${POSTGRES_BACKUP_DIR:-./backups/postgres}"

backup_dir="$(repo_path "$POSTGRES_BACKUP_DIR")"
mkdir -p "$backup_dir"
ts="$(date +%Y%m%d-%H%M%S)"
out="$backup_dir/${POSTGRES_DB}-${ts}.sql.gz"

docker exec "$POSTGRES_CONTAINER_NAME" pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" | gzip > "$out"
ls -lh "$out"
