# LAN access

Default `.env` is local-only:

```env
DB_HOST_BIND=0.0.0.0
DASHBOARD_HOST_BIND=127.0.0.1
```

Recommended setup:

- Keep dashboard bound to `127.0.0.1` and expose it through Caddy at `https://db.home.arpa`.
- Change DB/admin panel binding to the server LAN IP only when you are ready for firewall rules.

For LAN DB/admin panel access:

```env
DB_HOST_BIND=192.168.1.126
```

Restart:

```bash
./scripts/restart.sh
```

Then use:

- `https://db.home.arpa` for the dashboard through Caddy
- `http://db.home.arpa:5050` for pgAdmin
- `http://db.home.arpa:5540` for RedisInsight
- `http://db.home.arpa:7474` for Neo4j Browser
- `http://db.home.arpa:9001` for MinIO Console

Do not port-forward database/admin ports from the router to the internet.
