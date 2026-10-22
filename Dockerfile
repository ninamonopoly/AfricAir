# ---- build stage ----
FROM node:22-alpine AS build
WORKDIR /app
ARG GIT_SHA=unknown
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile
COPY . .
RUN pnpm build && \
    printf '{"commit":"%s","builtAt":"%s"}' "$GIT_SHA" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > dist/version.json

# ---- runtime stage ----
FROM nginx:alpine

# Build-time arguments for OCI image labels
ARG GIT_SHA=unknown
ARG VERSION=0.0.0
ARG BUILD_DATE=unknown
ARG SOURCE_URL=https://github.com/ninamonopoly/AfricAir

# OCI standard image labels
# https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.source="${SOURCE_URL}"

COPY --from=build /app/dist /usr/share/nginx/html
# envsubst template — nginx:alpine processes /etc/nginx/templates/*.template
# at startup, substituting API_UPSTREAM and APP_ENV, writing the result to
# /etc/nginx/conf.d/default.conf. The static docker.conf is no longer needed.
COPY deploy/nginx/templates/ /etc/nginx/templates/

# HEALTHCHECK uses BusyBox wget (available in nginx:alpine)
# --spider = HEAD-only request (no body downloaded)
# interval: check every 30s; timeout: fail if no response in 3s
# start-period: allow 5s for nginx to start before counting failures
# retries: 3 consecutive failures = unhealthy
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --spider --quiet http://localhost:8080/healthz || exit 1

EXPOSE 8080
