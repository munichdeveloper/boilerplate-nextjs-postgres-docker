# syntax=docker/dockerfile:1
FROM node:24-alpine@sha256:a34ab6d7f6f4813f4d0c5469d74685604b962fbdbf5793a7bc7b4998ecb867c8 AS builder
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1
COPY . .
# Keep dependencies/build in one layer, also efficient on VPS vfs storage.
# Optional CA mount for builds behind a corporate/session TLS proxy.
RUN --mount=type=secret,id=proxy_ca \
    if [ -f /run/secrets/proxy_ca ]; then export NODE_EXTRA_CA_CERTS=/run/secrets/proxy_ca; fi; \
    npm ci --no-audit --no-fund && \
    mkdir -p public && npm run build && \
    mkdir -p /output/.next /output/node_modules && \
    cp -a .next/standalone/. /output/ && \
    cp -a .next/static /output/.next/static && \
    cp -a public scripts drizzle /output/ && \
    cp -a node_modules/postgres node_modules/drizzle-orm /output/node_modules/

FROM node:24-alpine@sha256:a34ab6d7f6f4813f4d0c5469d74685604b962fbdbf5793a7bc7b4998ecb867c8 AS runtime
WORKDIR /app
ENV NODE_ENV=production NEXT_TELEMETRY_DISABLED=1 HOSTNAME=0.0.0.0 PORT=3000
COPY --from=builder --chown=node:node /output/ ./
USER node
EXPOSE 3000
HEALTHCHECK --interval=15s --timeout=5s --start-period=20s --retries=5 \
  CMD node -e "fetch('http://127.0.0.1:3000/api/health',{signal:AbortSignal.timeout(4000)}).then(r=>{if(!r.ok)process.exit(1)}).catch(()=>process.exit(1))"
CMD ["node", "scripts/start.cjs"]
