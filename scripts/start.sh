#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
  echo "No .env found. Creating from .env.example..."
  cp .env.example .env
fi

set -a
. ./.env
set +a

mkdir -p generated/pgadmin

cat > generated/pgadmin/servers.json <<JSON
{
  "Servers": {
    "1": {
      "Name": "db-postgres-pgvector",
      "Group": "Docker",
      "Host": "postgres",
      "Port": 5432,
      "MaintenanceDB": "${POSTGRES_DB}",
      "Username": "${POSTGRES_USER}",
      "Password": "${POSTGRES_PASSWORD}",
      "SSLMode": "prefer",
      "Favorite": true
    }
  }
}
JSON

chmod 644 generated/pgadmin/servers.json

docker compose up -d
echo "Started. Run: ./scripts/status.sh && ./scripts/verify.sh"
