# ---- build stage ----
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY server/package.json ./server/
RUN corepack enable && pnpm install --frozen-lockfile
COPY server/ ./server/
RUN pnpm --filter @africair/api build

# ---- runtime stage ----
FROM node:22-alpine
WORKDIR /app
COPY --from=build /app/server/dist ./server/dist
COPY --from=build /app/server/migrations ./server/migrations
COPY --from=build /app/node_modules ./node_modules
ENV NODE_ENV=production PORT=4000
EXPOSE 4000
CMD ["node", "server/dist/index.js"]
