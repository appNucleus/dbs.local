# Caddy route for db.home.arpa

Recommended root dashboard route:

```caddyfile
db.home.arpa {
    tls internal
    reverse_proxy 127.0.0.1:8080
}
```

Then:

```bash
sudo caddy fmt --overwrite /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

Open:

```text
https://db.home.arpa
```

The dashboard is a static page served by the `db-dashboard` BusyBox container. It does not authenticate users and does not proxy raw database protocols.

## Admin panel links

The dashboard links to these ports on the same hostname:

- pgAdmin: `http://db.home.arpa:5050`
- RedisInsight: `http://db.home.arpa:5540`
- Neo4j Browser: `http://db.home.arpa:7474`
- MinIO Console: `http://db.home.arpa:9001`

For these direct links to work from Windows/LAN clients, set this in `.env`:

```env
DB_HOST_BIND=192.168.1.126
```

Then restart:

```bash
./scripts/restart.sh
```

## Do not reverse proxy raw DB protocols with normal Caddy HTTP reverse_proxy

Do not use normal Caddy HTTP `reverse_proxy` for:

- PostgreSQL `5432`
- Redis `6379`
- Neo4j Bolt `7687`

Those are not HTTP services.

## Subpath warning

Avoid trying to host all admin panels under paths like `/pgadmin`, `/redis`, `/neo4j`, and `/minio` unless you explicitly configure each app for subpath/base-URL operation. Admin UIs often assume they own the site root and may break behind path-based reverse proxies.
