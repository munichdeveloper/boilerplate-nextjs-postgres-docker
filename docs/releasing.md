# Distribution release gates (manual, not executed by this PR)

The repository is already a GitHub Template. There are currently no releases or published application images established by this change. CI builds locally and does not push images. Publishing is **only** `workflow_dispatch`; no push/tag/PR event publishes or deploys.

After review and explicit publication approval:

1. Merge through the repository review process, then create an approved real `vX.Y.Z` tag/release. Configure the `image-release` GitHub Environment with required reviewers where supported; this PR does not alter repository settings. Enable Actions package-write permission if organization policy requires it.
2. Dispatch **Publish approved image** from the reviewed default branch with that existing tag. It builds the tag on amd64/arm64, logs in using the scoped `GITHUB_TOKEN`, and publishes `ghcr.io/munichdeveloper/boilerplate-nextjs-postgres-docker:vX.Y.Z` with provenance/SBOM. No PAT or invented credentials are needed. Do not reuse an existing version tag.
3. Set the GHCR package visibility to **Public** (first publication can be private). Verify an anonymous pull without cached login, both architectures, image health, and the smoke test using that image. Record the immutable digest in the release notes and `.env.production.example` as the recommended image. The operator still must explicitly set `APP_IMAGE`.
4. Publish the reviewed Compose file as a release asset or at its actual raw Git tag URL. Verify HTTP 200, expected contents, and `docker compose ... config --quiet` using synthetic values. Use that immutable URL in the README badge, URL-encoded using e.g. Python `urllib.parse.quote(url, safe='')`. Do not link an invented release.
5. On an already authorized non-production Hostinger VPS, verify Compose import, required ENV interpolation, secure password entry, internal networking, completed migration dependency, image pull and HTTPS/health. If secure ENV entry is unavailable, keep the button marked blocked and direct users to SSH/manual installation.
6. Only after all gates succeed remove **staged** wording and record the tested release, import date and results. No resource purchase or live deployment is authorized by this PR.

The branch URL in the staged badge exists for review after pushing; it is mutable and not a stable distribution release. Manual VPS installation is equally supported and uses the same file/images.

## Security verification scope

Runtime `npm audit --omit=dev` is clean after updating Next.js to 16.4.5 and Drizzle ORM to 0.45.4. The full audit still reports 12 moderate findings in development tooling (Drizzle Kit/esbuild and ESLint/typescript-eslint/minimatch); no forced breaking downgrade was applied. Recheck before release. Base images are pinned to verified multi-architecture digests (Node 24.22.2, PostgreSQL 16.15); npm audit does not scan OS packages. Run the organization’s image vulnerability scan and review SBOMs before publication.
