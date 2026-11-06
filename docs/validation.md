# Validation — 2026-11-06

Executed on a disposable managed Linux x86_64 environment, Node 24.22.1,
Docker 29.9.2 (rootless/vfs), Compose 2.40.3. No production server or data used.

| Command / check | Result |
| --- | --- |
| `npm ci` | Passed with committed lockfile |
| `npm run lint` | Passed; replaced removed Next.js lint command with ESLint flat config |
| `npm test` | 2 tests passed, including credential URL encoding and missing configuration |
| `npm run build` | Passed on Next.js 16.4.5 without database secrets |
| `npm audit --omit=dev --audit-level=high` | 0 vulnerabilities |
| `npm audit --audit-level=high` | 0 high/critical; 12 moderate development-tool findings remain |
| `docker build --secret id=proxy_ca,src="$CODEX_PROXY_CERT" -t boilerplate:test .` | Passed; optional session CA only, not embedded in image |
| `tests/compose-smoke.sh` | Passed; final run projects `template-smoke-6921-a/b`, ports 18081/18082 |
| Public raw Compose download + `cmp` | HTTP success, identical to reviewed file |
| Public Compose `config --quiet` with synthetic values | Passed |
| Missing each of four required variables | Rejected as expected by smoke test |
| `git diff --check` / `bash -n tests/compose-smoke.sh` | Passed |

The smoke test asserts: both DB/web healthchecks succeed; migrations replay with
one journal entry; runtime UID is non-root; app DB role is not a superuser and
cannot create tables; no PostgreSQL port is published; the database network is
internal; localhost web endpoints work; A's row is absent from B; A's app password
cannot authenticate from B's web container to B's database; volumes differ;
A's row survives `down` (without `-v`) and `up`; a custom-format dump restores
into a separate scratch database with the expected row; stopping B's database
produces a generic 503 without an error/connection string. Cleanup removed both
test stacks, networks and temporary volumes.

Initial vfs runs exhausted the environment's 8 GB filesystem. Build layers were
consolidated; disposable build cache and host dependency artifacts were removed
before rerunning successfully. The negative credential test was corrected to use
the web-to-DB network path, since the official PostgreSQL image trusts its own
loopback. Neither workaround relaxes production authentication or TLS validation.

The staged badge pins `compose.production.yml` at public commit
`d9227fc3e9c26206afc4826e24028ba4242844bc`. Required synthetic values used for quiet
validation were `APP_IMAGE=boilerplate:test`, `POSTGRES_DB=synthetic`,
`POSTGRES_PASSWORD=synthetic-admin`, `APP_DB_PASSWORD=synthetic-app`.
No source build directive exists in that Compose file.

Not verified: GHCR publication/anonymous pull of the application image, arm64
runtime, image OS vulnerability scan, Hostinger Docker Manager import/secure ENV
entry, real DNS/TLS issuance, offsite recovery or live VPS operation. These are
explicit [release gates](releasing.md); the badge remains staged. Base image pulls
were successful, but no application image was pushed. CI mirrors the local checks
and publishing has only a manual dispatch trigger.
