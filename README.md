# Next.js + PostgreSQL + Docker template

MIT-licensed Next.js 16 / React / TypeScript / Tailwind / Drizzle starter. Develop locally with npm, then run the same portable Docker Compose stack on a Hostinger, Hetzner, Netcup or other Linux VPS. No Hostinger runtime APIs, Horizons or managed Node.js hosting are required.

**Distribution status: staged.** This PR prepares the production stack. No public application image or release has been published or Hostinger import validated. Do not treat the button as a working one-click installation. See [release gates](docs/releasing.md).

## Create your project

This repository is already enabled as a GitHub Template. Choose **Use this template → Create a new repository**, or fork it to retain upstream history. Alternatively:

```sh
git clone https://github.com/munichdeveloper/boilerplate-nextjs-postgres-docker.git
cd boilerplate-nextjs-postgres-docker
```

Template copies must adapt the README button/URLs and image names to their own distribution. Repository settings should have “Template repository” enabled; no settings changes are required here.

## Local development

Requires Node.js 24 LTS, npm, Git, Docker Engine and Compose v2 (`docker compose`).

```sh
npm ci
cp .env.example .env
docker compose up -d
npm run db:migrate
npm run dev
```

Open http://localhost:3000 and `/api/health`. `.env.example` contains **local-only** credentials; the development database binds to loopback. Never use these credentials or this development Compose file on a public server.

- `npm run lint`, `npm test`, `npm run build`: checks.
- `npm run db:generate`: generate SQL after editing `src/db/schema.ts`; review and commit **all** `drizzle/` SQL and metadata.
- `npm run db:migrate`: apply checked-in migrations locally.
- `npm run db:push`: development-only schema experiments; never a production migration path.
- `npm run db:studio`: local database UI.

Existing development databases created with `db:push` need a reviewed migration baseline before `db:migrate`; the initial migration intentionally does not overwrite existing tables. Back up existing data and do not delete an old volume to work around a migration error.

The example schema has users and posts. `src/db/index.ts` keeps a lazy connection for builds without database secrets. `/api/health` dynamically checks the database and returns 200 or a generic 503 without connection details.

## Install A: Deploy on Hostinger (staged / untested)

<!-- HOSTINGER_BUTTON -->
[![Deploy on Hostinger](https://assets.hostinger.com/vps/deploy.svg)](https://www.hostinger.com/docker-hosting?compose_url=https%3A%2F%2Fraw.githubusercontent.com%2Fmunichdeveloper%2Fboilerplate-nextjs-postgres-docker%2Fd9227fc3e9c26206afc4826e24028ba4242844bc%2Fcompose.production.yml)

**Staged / not deployment-validated.** This public Compose URL is pinned to an existing review commit because no release tag exists yet. Image publication, secure ENV entry and Hostinger import are pending.
<!-- /HOSTINGER_BUTTON -->

Uses the [official Hostinger button syntax](https://www.hostinger.com/support/deploy-on-hostinger-button/). The link imports a **single Compose file**, not a source checkout. It references images only and requires a published `APP_IMAGE`; there is no `build: .`. No affiliate/referral identifier is included.

After an approved release, choose a suitable VPS with Docker Manager, review its price yourself, and import the Compose file. **Before starting**, securely supply `APP_IMAGE`, `POSTGRES_DB`, `POSTGRES_PASSWORD` and `APP_DB_PASSWORD`. Generate two different passwords with `openssl rand -hex 32`. The app password is separate from the PostgreSQL administrator password. Keep these values out of Git and support screenshots.

**Open validation blocker:** whether Docker Manager supports Compose required-value interpolation, secure environment input, internal networks and completed one-shot service dependencies has not been verified. If secure ENV input is unavailable, stop and use the manual SSH path below. Do not replace missing values with default credentials. The default web port is loopback-only: configure DNS and the host TLS reverse proxy as in Install B. A successful import alone does not establish secure production operation.

## Install B: any Linux VPS

Follow the complete [VPS installation and operations guide](docs/vps.md). It covers prerequisites, DNS/HTTPS, protected environment setup, migrations, health, logs, updates, rollback, backup and an isolated restore test. It works on Hostinger via SSH as well as other hosts.

The production stack contains a non-root standalone web image, a one-shot migration job and PostgreSQL 16 with a persistent project-scoped volume. PostgreSQL has no published port and is attached only to an internal network. The app has table/sequence privileges but no schema migration or administrator privileges. Each installation needs a unique Compose project name, port and credentials.

Build/test locally without publishing:

```sh
docker build -t boilerplate:test .
APP_IMAGE=boilerplate:test tests/compose-smoke.sh
```

This smoke test creates and removes only uniquely named disposable stacks and their volumes. It needs free localhost ports 18081/18082 (override `TEST_PORT_A/B`).

## Operator responsibilities

Operators own availability, security patches, backups, restore testing and privacy compliance. Compose environment values are visible to Docker administrators; use a trusted dedicated host and protect `.env.production` and backups. This starter does not guarantee reseller or multi-tenant isolation; validate tenant boundaries separately. PostgreSQL major upgrades, high availability, authentication and application authorization require project-specific work.

## License

MIT, as declared in `package.json`.
