#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

set -a
. ./.env
set +a

mkdir -p backups/postgres
ts="$(date +%Y%m%d-%H%M%S)"
out="backups/postgres/${POSTGRES_DB}-${ts}.sql.gz"

docker exec db-postgres pg_dump -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" | gzip > "${out}"
ls -lh "${out}"
