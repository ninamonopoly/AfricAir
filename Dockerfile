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
COPY --from=build /app/dist /usr/share/nginx/html
COPY deploy/nginx/docker.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
