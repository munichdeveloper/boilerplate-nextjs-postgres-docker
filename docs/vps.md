# Portable VPS installation and operations

The application image is **not published yet**. Finish [the release gates](releasing.md) before using the image-only distribution. No command here provisions or pays for a server. Commands below run on your own non-production test VPS first.

## Prerequisites and DNS/TLS

Use a supported Linux VPS (e.g. Ubuntu 24.04 LTS), SSH keys, a sudo-capable account, Docker Engine and the Compose v2 plugin from the [official Docker installation guide](https://docs.docker.com/engine/install/). Allow SSH only from trusted addresses and allow incoming TCP 80/443 for HTTPS. Do not open 3000 or 5432. Docker-published ports can bypass UFW; keep the loopback binding below. Budget for memory (at least 2 GB for this small stack), disk, offsite backups and monitoring. Docker administrators effectively have root privileges.

Point your domain's A record (and AAAA only if IPv6 is configured) to the VPS. Install Caddy using its [official instructions](https://caddyserver.com/docs/install) as a **host service**. Example `/etc/caddy/Caddyfile`:

```caddyfile
app.example.com {
    encode zstd gzip
    reverse_proxy 127.0.0.1:3000
}
```

Replace the domain. Run `sudo caddy validate --config /etc/caddy/Caddyfile`, then `sudo systemctl reload caddy`. Caddy obtains/renews TLS certificates when DNS resolves and 80/443 are reachable. Do not expose the service publicly until `curl -fsS https://YOUR_DOMAIN/api/health` succeeds and the certificate is valid. If a proxy lives in Docker, use a deliberate shared proxy network; its loopback is not the host loopback. Leave PostgreSQL private.

## Protected configuration and installation

After an approved release, use the **actual immutable raw URL** recorded in that release. Until then use a source checkout of this PR for disposable testing; do not invent a release URL. A concrete staged test path is:

```sh
git clone --branch feat/28-portable-vps-template https://github.com/munichdeveloper/boilerplate-nextjs-postgres-docker.git my-app
cd my-app
docker build -t template:local .
```

For that local build set `APP_IMAGE=template:local`, skip `dc pull`, and continue below in this directory. This is a source-build test alternative, not a published distribution.

```sh
mkdir -p ~/my-app && cd ~/my-app
# Copy/download the reviewed compose.production.yml and .env.production.example here.
cp .env.production.example .env.production
chmod 600 .env.production
openssl rand -hex 32 # administrator password; save privately
openssl rand -hex 32 # different application password; save privately
```

Edit `.env.production` privately. Set `APP_IMAGE` to the public release image digest (`ghcr.io/OWNER/REPO@sha256:...`), `POSTGRES_DB=app`, both generated passwords, `WEB_PORT=3000`, and `WEB_BIND_IP=127.0.0.1`. Do not use an empty value or local example credentials. No build or runtime secret goes into an image. The only public `NEXT_PUBLIC_APP_URL` from local examples is currently unused; future `NEXT_PUBLIC_*` settings are build-time public data, never secrets.

Use a stable unique project name. In the shell examples define:

```sh
dc() { docker compose --env-file .env.production -p my-app -f compose.production.yml "$@"; }
dc config --quiet # validates required values without printing interpolated secrets
dc pull
dc up -d --wait --wait-timeout 180
dc ps
curl -fsS http://127.0.0.1:3000/api/health
```

Never paste ordinary `dc config` output into tickets: it contains secrets. A second installation uses another directory, project name, port and independently generated credentials. Production Compose does not load `.env.production` automatically; pass `--env-file` every time.

`up` waits for PostgreSQL, runs the versioned Drizzle migrations once, provisions the restricted `app` login and grants table/sequence access, then starts web. Replays are idempotent and cooperating migration jobs use an advisory lock. The migration image and web image must be identical. The PostgreSQL administrator password is passed only to PostgreSQL/migrate, not web. The migration container exits successfully; do not interpret that as an outage. Inspect its exit status/logs if startup fails. Never substitute `db:push`.

Changing `POSTGRES_PASSWORD` does **not** rotate credentials in an existing volume. Plan a manual SQL password rotation in a maintenance window; update the protected file consistently before recreating services. Changing the app password requires rerunning migrate, which changes the database login, and recreating web. Schema-specific extensions/permissions and destructive migrations need review before release. Default grants cover current tables/sequences; each deployment migration refreshes them.

## Health, logs and maintenance

```sh
dc ps
dc logs --tail=100 web migrate postgres
curl -fsS https://YOUR_DOMAIN/api/health
```

Configure external HTTPS health monitoring and disk/backup alerts. Healthchecks detect failures; Docker's restart policy restarts crashed containers, **not** merely unhealthy ones. Logs rotate locally, but review application logs for private data before forwarding. Patch the host and review base-image/application dependency updates regularly. Keep the image and Compose version/digest together in your deployment inventory. Do not run `down -v` on an installation whose data matters.

## Backup and isolated restore test

Use this on a disposable installation before production. Schedule backups offsite encrypted with retention and test them regularly. Dumps contain personal data. `pg_dump` covers one database, not cluster roles/server configuration; the migration job recreates the app role on a fresh stack. Record image versions and protect configuration separately.

```sh
umask 077
mkdir -p backups
backup="backups/app-$(date -u +%Y%m%dT%H%M%SZ).dump"
dc exec -T postgres sh -c 'pg_dump -U postgres -d "$POSTGRES_DB" -Fc' > "$backup"
test -s "$backup"
# Test in a separate scratch database, never overwrite the source:
dc exec -T postgres createdb -U postgres restore_test
dc exec -T postgres pg_restore -U postgres -d restore_test --no-owner --no-acl --exit-on-error < "$backup"
dc exec -T postgres psql -U postgres -d restore_test -c 'SELECT count(*) FROM users; SELECT count(*) FROM posts;'
# Compare row counts and inspect representative data against the source.
# Remove only the scratch database when the checks pass:
dc exec -T postgres dropdb -U postgres restore_test
```

For recovery, restore to a **new isolated stack/volume**, provision roles with its matching migration image, restore into an empty target DB (avoid conflicting pre-created tables), then validate data, permissions and application health before switching traffic. Rehearse this procedure for each schema release. Never delete the sole original volume during recovery.

## Updates and rollback

1. Review release SQL and compatibility, take a backup and prove a restore on a scratch DB. Record the old image digest/config. For incompatible schema changes, schedule downtime and stop web first.
2. Set `APP_IMAGE` to the approved new digest in `.env.production`; `dc pull`.
3. `dc stop web`, then `dc run --rm migrate`. If it fails, investigate before starting web.
4. `dc up -d --force-recreate --wait --wait-timeout 180`; verify HTTPS health and application behavior.
5. Roll back the **application only** by restoring the old digest and recreating web (`dc up -d --no-deps --force-recreate web`) only if the schema is backward compatible. SQL migrations are not automatically reversed. Incompatible changes require a tested database restore into a separate stack and a deliberate traffic cutover; restore can lose writes since the backup.

A PostgreSQL major version upgrade needs `pg_upgrade` or a rehearsed dump/restore; never just change the major tag against the old volume.
