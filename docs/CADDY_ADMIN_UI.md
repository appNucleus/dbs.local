# Caddy route for dbs.home.arpa

This file documents the intended Caddy setup for the DB dashboard only.

The dashboard is a static BusyBox page. It should be exposed through host Caddy:

```text
https://dbs.home.arpa
        |
        v
host Caddy
        |
        v
127.0.0.1:8003
        |
        v
db-dashboard BusyBox container
```

The dashboard should stay bound to localhost in Docker:

```env
DASHBOARD_HOST_BIND=127.0.0.1
DASHBOARD_PORT=8003
```

The Docker mapping may look like either of these:

```text
127.0.0.1:8003->8080/tcp
```

or:

```text
127.0.0.1:8003->8003/tcp
```

Both are acceptable. Caddy only needs the host-side endpoint:

```text
127.0.0.1:8003
```

## Caddyfile entry

Add this to `/etc/caddy/Caddyfile`:

```caddyfile
dbs.home.arpa {
    tls internal
    reverse_proxy 127.0.0.1:8003
}
```

Example full local Caddyfile shape:

```caddyfile
app.home.arpa {
    tls internal
    reverse_proxy 127.0.0.1:8001
}

mcp.home.arpa {
    tls internal
    reverse_proxy 127.0.0.1:8002
}

dbs.home.arpa {
    tls internal
    reverse_proxy 127.0.0.1:8003
}
```

## Reload Caddy

Run:

```bash
sudo caddy fmt --overwrite /etc/caddy/Caddyfile
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
sudo systemctl status caddy --no-pager -l
```

## Test from the server

Test BusyBox directly through the host-local port:

```bash
curl -I http://127.0.0.1:8003
```

Expected:

```text
HTTP/1.1 200 OK
```

Test Caddy locally:

```bash
curl -kI --resolve dbs.home.arpa:443:127.0.0.1 https://dbs.home.arpa
```

Expected:

```text
HTTP/2 200
```

## Test from Windows or another LAN client

DNS should resolve to the Ubuntu server:

```powershell
Resolve-DnsName dbs.home.arpa
```

Expected IP:

```text
192.168.1.126
```

Then test HTTPS through Caddy:

```powershell
curl.exe -kI https://dbs.home.arpa
```

Expected:

```text
HTTP/2 200
```

Open:

```text
https://dbs.home.arpa
```

If the browser shows a certificate warning, install/trust the Caddy local root CA on the client machine.

## Admin panel links

The dashboard should link to DB/admin services directly by hostname and port.

Expected links:

- pgAdmin: `http://dbs.home.arpa:5050`
- RedisInsight: `http://dbs.home.arpa:5540`
- Neo4j Browser: `http://dbs.home.arpa:7474`
- MinIO Console: `http://dbs.home.arpa:9001`

Raw protocol endpoints:

- PostgreSQL: `dbs.home.arpa:5432`
- Redis: `dbs.home.arpa:6379`
- Neo4j Bolt: `bolt://dbs.home.arpa:7687`
- MinIO S3 API: `http://dbs.home.arpa:9000`

For these direct DB/admin links to work from LAN clients, the DB/admin services should be published by Docker using:

```env
DB_HOST_BIND=0.0.0.0
```

and access should be controlled by firewall policy.

## Do not reverse proxy raw DB protocols with normal Caddy HTTP reverse_proxy

Do not use normal Caddy HTTP `reverse_proxy` for these raw database protocols:

- PostgreSQL `5432`
- Redis `6379`
- Neo4j Bolt `7687`
- MinIO S3 API `9000`

Those are not normal dashboard web pages.

The intended model is:

```text
Dashboard:
  Browser -> Caddy HTTPS -> 127.0.0.1:8003 -> BusyBox dashboard

DB/admin services:
  LAN client -> dbs.home.arpa:service_port -> Docker-published service port
```

## Subpath warning

Avoid hosting all admin panels under paths like `/pgadmin`, `/redis`, `/neo4j`, and `/minio` unless each app is explicitly configured for subpath/base-URL operation.

Admin UIs often assume they own the site root and can break behind path-based reverse proxies.

## Expected Docker port state

After deployment:

```bash
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep db-
```

Expected dashboard:

```text
db-dashboard      127.0.0.1:8003->8080/tcp
```

or:

```text
db-dashboard      127.0.0.1:8003->8003/tcp
```

Expected DB/admin services:

```text
db-pgadmin        443/tcp, 0.0.0.0:5050->80/tcp
db-postgres       0.0.0.0:5432->5432/tcp
db-redis          0.0.0.0:6379->6379/tcp
db-redisinsight   0.0.0.0:5540->5540/tcp
db-neo4j          0.0.0.0:7474->7474/tcp, 0.0.0.0:7687->7687/tcp
db-minio          0.0.0.0:9000-9001->9000-9001/tcp
```
