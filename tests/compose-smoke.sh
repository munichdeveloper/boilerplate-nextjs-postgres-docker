#!/usr/bin/env bash
# Destructive ONLY to the uniquely named temporary test projects created here.
set -euo pipefail
cd "$(dirname "$0")/.."
export APP_IMAGE="${APP_IMAGE:-boilerplate:test}"
export POSTGRES_DB=smoke
export POSTGRES_PASSWORD="$(openssl rand -hex 24)"
export APP_DB_PASSWORD="$(openssl rand -hex 24)"
export WEB_BIND_IP=127.0.0.1
prefix="template-smoke-$$"
a="${prefix}-a"
b="${prefix}-b"
WEB_PORT="${TEST_PORT_A:-18081}"
export WEB_PORT
compose() { docker compose -p "$1" -f compose.production.yml "${@:2}"; }
cleanup() {
  compose "$a" down -v --remove-orphans >/dev/null
  compose "$b" down -v --remove-orphans >/dev/null
}
trap cleanup EXIT
# Quiet validation must not print secrets. Each required variable fails closed.
compose "$a" config --quiet
for key in APP_IMAGE POSTGRES_DB POSTGRES_PASSWORD APP_DB_PASSWORD; do
  if env -u "$key" docker compose -f compose.production.yml config --quiet > /dev/null 2>&1; then
    echo "Missing $key was accepted" >&2; exit 1
  fi
done
compose "$a" up -d --wait --wait-timeout 180
password_a="$APP_DB_PASSWORD"
admin_a="$POSTGRES_PASSWORD"
export POSTGRES_PASSWORD="$(openssl rand -hex 24)"
export APP_DB_PASSWORD="$(openssl rand -hex 24)"
WEB_PORT="${TEST_PORT_B:-18082}"
compose "$b" up -d --wait --wait-timeout 180
for project in "$a" "$b"; do
  compose "$project" exec -T web node -e "fetch('http://127.0.0.1:3000/api/health').then(async r=>{if(r.status!==200||(await r.json()).database!=='connected')process.exit(1)})"
  test -z "$(docker port "$(compose "$project" ps -q postgres)")"
  test "$(compose "$project" exec -T postgres psql -U postgres -d smoke -Atc "select rolsuper from pg_roles where rolname='app'")" = f
  test "$(compose "$project" exec -T web id -u)" != 0
  migration_id="$(compose "$project" ps -aq migrate)"
  docker start -a "$migration_id"
  test "$(docker inspect -f '{{.State.ExitCode}}' "$migration_id")" = 0
  test "$(compose "$project" exec -T postgres psql -U postgres -d smoke -Atc 'select count(*) from drizzle.__drizzle_migrations')" = 1
done
# Verify the runtime login can use tables but cannot create schema objects.
compose "$a" exec -T web node -e 'const sql=require("postgres")(require("./scripts/database-url.cjs").databaseUrl(process.env)); (async()=>{try {await sql`select * from users`;let denied=false;try {await sql`create table forbidden(id int)`}catch(e){denied=e.code==="42501"}if(!denied)process.exitCode=1;}finally{await sql.end()}})().catch(()=>process.exit(1))'
curl -fsS --noproxy "*" "http://127.0.0.1:${TEST_PORT_A:-18081}/api/health" >/dev/null
curl -fsS --noproxy "*" "http://127.0.0.1:${TEST_PORT_B:-18082}/api/health" >/dev/null
# Different data and credentials, with no shared database network or volume.
compose "$a" exec -T postgres psql -U postgres -d smoke -c "insert into users(name,email) values ('persistence','only-a@example.test')"
test "$(compose "$b" exec -T postgres psql -U postgres -d smoke -Atc 'select count(*) from users')" = 0
if compose "$b" exec -T -e PGPASSWORD="$password_a" postgres psql -h 127.0.0.1 -U app -d smoke -c 'select 1' > /dev/null 2>&1; then
  echo 'Cross-instance password unexpectedly accepted' >&2; exit 1
fi
test "$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/var/lib/postgresql/data"}}{{.Name}}{{end}}{{end}}' "$(compose "$a" ps -q postgres)")" != "$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/var/lib/postgresql/data"}}{{.Name}}{{end}}{{end}}' "$(compose "$b" ps -q postgres)")"
test "$(docker network inspect -f '{{.Internal}}' "${a}_database")" = true
# A's data survives a full container recreation with its original credentials.
compose "$a" down
(export POSTGRES_PASSWORD="$admin_a" APP_DB_PASSWORD="$password_a" WEB_PORT="${TEST_PORT_A:-18081}"; compose "$a" up -d --wait --wait-timeout 180)
test "$(compose "$a" exec -T postgres psql -U postgres -d smoke -Atc 'select count(*) from users')" = 1
# Restore to an isolated scratch DB; never drop the source database.
compose "$a" exec -T postgres createdb -U postgres restore_test
compose "$a" exec -T postgres pg_dump -U postgres -d smoke -Fc | compose "$a" exec -T postgres pg_restore -U postgres -d restore_test --no-owner --no-acl --exit-on-error
test "$(compose "$a" exec -T postgres psql -U postgres -d restore_test -Atc 'select count(*) from users')" = 1
compose "$a" exec -T postgres dropdb -U postgres restore_test
# Actual failed DB connections return a generic 503; no credentials in response.
compose "$b" stop postgres
compose "$b" exec -T web node -e "fetch('http://127.0.0.1:3000/api/health').then(async r=>{const b=await r.json();if(r.status!==503||b.error||b.database!=='disconnected')process.exit(1)})"
echo 'PASS: two stacks, migration replay, health/failure, private DB, distinct credentials/volumes, persistence, backup/restore'
