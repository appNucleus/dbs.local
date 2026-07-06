#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

set -a
[ -f .env ] && source .env
set +a

POSTGRES_USER="${POSTGRES_USER:-langgraph_user}"
POSTGRES_DB="${POSTGRES_DB:-langgraph_app}"
REDIS_PASSWORD="${REDIS_PASSWORD:-change_me_redis_2026}"
NEO4J_USERNAME="${NEO4J_USERNAME:-neo4j}"
NEO4J_PASSWORD="${NEO4J_PASSWORD:-change_me_neo4j_2026}"
MINIO_ROOT_USER="${MINIO_ROOT_USER:-minioadmin}"
MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD:-change_me_minio_2026}"
MINIO_DEFAULT_BUCKET="${MINIO_DEFAULT_BUCKET:-langgraph-app}"
DASHBOARD_PORT="${DASHBOARD_PORT:-8080}"

printf '\n===== Containers =====\n'
docker compose ps

printf '\n===== Dashboard =====\n'
curl -fsS "http://127.0.0.1:${DASHBOARD_PORT}/" >/dev/null && echo "dashboard: ok"

printf '\n===== PostgreSQL =====\n'
docker exec db-postgres pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"
docker exec db-postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT extname FROM pg_extension WHERE extname='vector';"

printf '\n===== Redis =====\n'
docker exec db-redis redis-cli -a "$REDIS_PASSWORD" ping

printf '\n===== Neo4j =====\n'
docker exec db-neo4j cypher-shell -u "$NEO4J_USERNAME" -p "$NEO4J_PASSWORD" "RETURN 1 AS ok;"

printf '\n===== MinIO =====\n'
docker exec db-minio mc alias set local http://127.0.0.1:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null
docker exec db-minio mc ls "local/$MINIO_DEFAULT_BUCKET" >/dev/null || docker exec db-minio mc ls local

printf '\nAll checks completed.\n'
