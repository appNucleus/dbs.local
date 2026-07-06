# db.local

Local Docker database/storage stack for a LangGraph/FastAPI/LLM app, with GitHub Actions deployment and automatic rollback support.

## Included

Long-running containers in this stack:

1. `db-postgres` - PostgreSQL 17 + pgvector
2. `db-pgadmin` - pgAdmin PostgreSQL admin UI
3. `db-redis` - Redis
4. `db-redisinsight` - RedisInsight Redis admin UI
5. `db-neo4j` - Neo4j Community + Neo4j Browser
6. `db-minio` - MinIO S3-compatible object storage + console
7. `db-dashboard` - tiny BusyBox static HTML launcher page

Temporary one-shot container:

- `db-minio-init` - creates the default MinIO bucket, then exits

PostgreSQL and Redis do not include full web admin panels inside their own DB containers, so this project adds `pgAdmin` and `RedisInsight`.

## Deployment model

This repo now follows the same successful-deployment backup and rollback pattern as the strategy repo, adjusted safely for a DB stack.

Important difference: this repo has persistent database volumes and mostly third-party images. Deployment rollback restores the last successful Compose source and runtime `.env`; it never deletes database volumes.

Server folders expected for your current server:

```text
/home/abrar/actions_db.local
/home/abrar/backup_db.local
```

Runtime environment file used by GitHub Actions:

```text
/home/abrar/.config/db.local/runtime.env
```

The workflow creates that runtime env file from `.env.example` on first deployment and preserves it afterward.

## GitHub Actions deployment

Workflow file:

```text
.github/workflows/deploy-release.yml
```

Trigger:

```text
push to release branch
```

Expected self-hosted runner labels:

```text
self-hosted, Linux, X64, db-prod
```

Recommended server-side runner folder:

```text
/home/abrar/actions_db.local
```

Recommended backup folder:

```text
/home/abrar/backup_db.local
```

The deployment flow is:

```text
checkout release commit
validate scripts and server prerequisites
create/preserve runtime.env
generate pgAdmin servers.json
validate docker compose config
prepare rollback point
start candidate stack with health checks
run smoke test
replace successful deployment backup
on failure, restore last successful Compose source and runtime env
```

The backup folder keeps exactly one successful deployment backup, matching the strategy repo. This backup is a compact source/config snapshot, not a database-data backup.

## Quick start manually on the server

```bash
mkdir -p ~/db.local
cd ~/db.local

# copy this project here, then:
cp .env.example .env
nano .env

chmod +x scripts/*.sh
./scripts/start.sh --wait
./scripts/status.sh
./scripts/verify.sh
```

Or use the same local deploy wrapper as GitHub Actions:

```bash
DEPLOY_ENV_FILE="$HOME/.config/db.local/runtime.env" ./scripts/deploy-local.sh
```

## `.env` controls repeated names, paths, ports, and credentials

The `.env.example` file controls:

- server deployment folders: `ACTIONS_ROOT`, `BACKUP_ROOT`, `DEPLOY_ENV_FILE`
- generated/config folders: `GENERATED_DIR`, `PGADMIN_SERVERS_JSON`, `DASHBOARD_WWW_DIR`, `POSTGRES_BACKUP_DIR`
- Compose project/network names
- container names
- Docker volume names
- host bind addresses
- service ports
- default usernames/passwords
- MinIO default bucket

This keeps repeated values consistent across Compose, scripts, and GitHub Actions.

## Default localhost endpoints

| Service | Endpoint |
|---|---|
| Static dashboard | `http://127.0.0.1:8080` |
| PostgreSQL | `127.0.0.1:5432` |
| pgAdmin | `http://127.0.0.1:5050` |
| Redis | `127.0.0.1:6379` |
| RedisInsight | `http://127.0.0.1:5540` |
| Neo4j Browser | `http://127.0.0.1:7474` |
| Neo4j Bolt | `bolt://127.0.0.1:7687` |
| MinIO S3 API | `http://127.0.0.1:9000` |
| MinIO Console | `http://127.0.0.1:9001` |

## Recommended Caddy route for db.home.arpa

Keep the dashboard bound to localhost:

```env
DASHBOARD_HOST_BIND=127.0.0.1
DASHBOARD_PORT=8080
```

Add this to `/etc/caddy/Caddyfile`:

```caddyfile
db.home.arpa {
    tls internal
    reverse_proxy 127.0.0.1:8080
}
```

Then reload Caddy:

```bash
sudo caddy fmt --overwrite /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

Open:

```text
https://db.home.arpa
```

The dashboard links point to the admin panels by hostname and port, for example `http://db.home.arpa:5050`.

## Default credentials

| Service | Username | Password |
|---|---|---|
| PostgreSQL | `langgraph_user` | `change_me_postgres_2026` |
| pgAdmin | `admin@local.dev` | `change_me_pgadmin_2026` |
| Redis | default user | `change_me_redis_2026` |
| RedisInsight | no app login by default | Redis connection is preconfigured |
| Neo4j | `neo4j` | `change_me_neo4j_2026` |
| MinIO | `minioadmin` | `change_me_minio_2026` |

Change passwords in the runtime env before first serious use.

## LAN access through db.home.arpa

Default database/admin-panel bind is local-only:

```env
DB_HOST_BIND=127.0.0.1
```

For LAN access, change it to your server IP:

```env
DB_HOST_BIND=192.168.1.126
```

Then:

```bash
./scripts/restart.sh
```

LAN endpoints:

| Service | Endpoint |
|---|---|
| Static dashboard through Caddy | `https://db.home.arpa` |
| PostgreSQL | `db.home.arpa:5432` |
| pgAdmin | `http://db.home.arpa:5050` |
| Redis | `db.home.arpa:6379` |
| RedisInsight | `http://db.home.arpa:5540` |
| Neo4j Browser | `http://db.home.arpa:7474` |
| Neo4j Bolt | `bolt://db.home.arpa:7687` |
| MinIO S3 API | `http://db.home.arpa:9000` |
| MinIO Console | `http://db.home.arpa:9001` |

Do not port-forward these ports from your router to the internet.

## Firewall example

```bash
sudo ufw allow from 192.168.1.0/24 to any port 5432 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 5050 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 6379 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 5540 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 7474 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 7687 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 9000 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 9001 proto tcp
```

The dashboard itself can stay private behind Caddy on 80/443, so you do not need to expose port 8080 to LAN.

## App connection strings

Same server:

```env
DATABASE_URL=postgresql+asyncpg://langgraph_user:change_me_postgres_2026@127.0.0.1:5432/langgraph_app
REDIS_URL=redis://:change_me_redis_2026@127.0.0.1:6379/0
NEO4J_URI=bolt://127.0.0.1:7687
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=change_me_neo4j_2026
S3_ENDPOINT_URL=http://127.0.0.1:9000
S3_ACCESS_KEY=minioadmin
S3_SECRET_KEY=change_me_minio_2026
S3_BUCKET=langgraph-app
```

LAN:

```env
DATABASE_URL=postgresql+asyncpg://langgraph_user:change_me_postgres_2026@db.home.arpa:5432/langgraph_app
REDIS_URL=redis://:change_me_redis_2026@db.home.arpa:6379/0
NEO4J_URI=bolt://db.home.arpa:7687
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=change_me_neo4j_2026
S3_ENDPOINT_URL=http://db.home.arpa:9000
S3_ACCESS_KEY=minioadmin
S3_SECRET_KEY=change_me_minio_2026
S3_BUCKET=langgraph-app
```

## Important password/volume note

PostgreSQL and Neo4j initialize credentials when their persistent volumes are first created. If you change `.env` after first startup, the old DB credentials may still remain in the existing volumes.

For a clean reset during testing:

```bash
./scripts/reset-all-data.sh
```

This deletes all stack volumes and should never be used by GitHub Actions.

## PostgreSQL logical backup

```bash
./scripts/backup-postgres.sh
```

By default this writes to:

```text
./backups/postgres
```

You can change that with:

```env
POSTGRES_BACKUP_DIR=./backups/postgres
```

## Hardware note

This stack is appropriate for a Core i5-6400T, 16 GB RAM, and SSD for 2-3 users, assuming the LLM/Ollama model inference load is separate or modest. Neo4j is the largest idle memory user in this stack; its heap/page-cache defaults are intentionally modest in `.env.example`.
