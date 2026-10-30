# Build Output

Files produced in `dist/` after running `pnpm build`:

- `dist/index.html`
- `dist/africair-mark.svg`
- `dist/manus-routes.json`
- `dist/assets/airports-BrwcO3ZA.js`
- `dist/assets/index-CBj_wgb2.css`
- `dist/assets/index-D8WT6gtn.js`
- `dist/assets/index.es-C05bQb9q.js`
- `dist/assets/pdf-o1MWN_TF.js`
- `dist/assets/react-CpYK3H_K.js`

Files in dist/ .

dist/
├── assets/
│   ├── airports-BrwcO3ZA.js
│   ├── index-CBj_wgb2.css
│   ├── index-D8WT6gtn.js
│   ├── index.es-C05bQb9q.js
│   ├── pdf-o1MWN_TF.js
│   └── react-CpYK3H_K.js
├── africair-mark.svg
├── index.html
└── manus-routes.json

Commands run: After git clone starting the project in my repository
winget install npm
npm install -g pnpm
pnpm --version
pnpm build
pnpm add -D typescript

git add ANSWERS.md
git commit -m "Update ANSWERS.md"
git push

cd dist/ and ls
cat vite.config.ts


Why do the file names under dist/assets/ contain hashes? What would break if they didn't?
The hashes (e.g. airports-BrwcO3ZA.js) are content fingerprints — Vite generates them from the file's contents at build time.

Why they exist — cache busting.

Browsers and CDNs cache static files aggressively. If you deploy a new version of airports.js but the filename stays the same, users get the old cached copy. With a hash in the name, any change to the file produces a new filename (e.g. airports-XyZ123.js), forcing the browser to fetch the new version.

What would break without them:

Users would see stale JS/CSS after a deployment until their cache expired or they hard-refreshed

A CDN like CloudFront would serve the old file indefinitely (TTL could be days/weeks)

You'd have to set short cache TTLs on every asset, killing the performance benefit of caching entirely

The trade-off that makes it work:

index.html is intentionally not hashed and should be served with Cache-Control: no-cache. It's the only file that changes on every deploy and tells the browser which hashed asset filenames to load. Everything under assets/ can then be cached forever (Cache-Control: max-age=31536000, immutable) safely.

What do tsc -b and vite build each do? Which one produces files in dist/?

tsc -b

Runs the TypeScript compiler in build mode. It reads tsconfig.json (and any referenced configs like tsconfig.app.json) and type-checks the entire project. It reports type errors but in this project it does not emit any .js files — the tsconfig.app.json likely has "noEmit": true. It's purely a type-safety gate.

vite build

Bundles the app using Rollup under the hood — transpiles TypeScript/TSX, resolves imports, applies the manual chunking from vite.config.ts, minifies, and writes the final output. This is what produces dist/.

Why run both?

Vite intentionally skips full type-checking during bundling (it just strips types) because it's much faster that way. So the two commands complement each other:

tsc -b → catches type errors

vite build → produces the deployable files

If tsc -b fails, the && in the build script (tsc -b && vite build) stops the pipeline before Vite runs, so you never deploy type-unsafe code.

Which one produces files in dist/?
vite build

Why --frozen-lockfile?

-frozen-lockfile tells pnpm to install exactly what's in pnpm-lock.yaml and fail if anything would change it.

Without it, pnpm might update the lockfile if package.json and pnpm-lock.yaml are out of sync — silently installing different dependency versions than what was tested.

Why it matters in CI/CD:

Guarantees every build uses the exact same dependency versions

Fails fast if someone forgot to commit an updated lockfile

Prevents "works on my machine" bugs caused by version drift

Makes builds reproducible and auditable

In local development you'd use plain pnpm install so the lockfile can update normally. In a pipeline, --frozen-lockfile is the safety net.



Delete pnpm-lock.yaml, reinstall, and describe what changed and why that is dangerous in CI.

The lockfile changed on one line — the TypeScript specifier updated from ^5.7.3 to ^5.9.3.

What happened: deleting the lockfile forced pnpm to re-resolve all dependencies from scratch against the semver ranges in package.json. TypeScript's range is ^5.7.3 (any 5.x ≥ 5.7.3), so pnpm picked the latest available — 5.9.3.

Why this is dangerous in CI:

A CI pipeline running pnpm install (without --frozen-lockfile) after someone accidentally deletes or forgets to commit the lockfile would silently pull 5.9.3 instead of 5.7.3

TypeScript minor/patch releases can introduce new type errors or change behaviour, breaking a build that previously passed

The build artifact produced is no longer identical to what was tested locally or in a previous run — reproducibility is gone

You'd have no easy way to know why the build suddenly broke, since no code changed

This is exactly why CI should always use pnpm install --frozen-lockfile — it would have caught this immediately with a hard failure instead of silently upgrading.

Commands run:
git add ANSWERS.md
git commit -m "Update ANSWERS.md"
git push

cat vite.config.ts /vi vite.config.ts escape :q! without saving


What do manualChunks and chunkSizeWarningLimit do? Which chunk is the largest, and why does that matter to a user on a 3G connection?

manualChunks

Overrides Rollup's default bundling by explicitly assigning modules to named chunks. In vite.config.ts:

jspdf, html2canvas, dompurify → pdf chunk

airports.json → airports chunk

react → react chunk

everything else → index chunk

Without this, Rollup might bundle everything into one giant file, or split it unpredictably.

chunkSizeWarningLimit

Just raises the threshold (from Vite's default 500 kB to 700 kB) at which Vite prints a warning about large chunks. It doesn't change the output — it silences the warning for pdf which is ~585 kB.

Which chunk is largest

pdf-o1MWN_TF.js — jsPDF alone is ~585 kB minified (noted in the config comment).

Why that matters on 3G

A typical 3G connection is ~1–2 Mbps. At 1 Mbps, 585 kB takes roughly 4–5 seconds to download just that one chunk. But the key insight is that manualChunks actually helps here:

The PDF chunk is only needed when a user downloads an itinerary — it can be lazy-loaded at that point rather than blocking the initial page load

airports and react are stable and rarely change, so they stay cached across deploys — a returning user on 3G doesn't re-download them

Only index (the app logic) needs to be fetched fresh after each deployment

Without manual chunking, every deploy would force a 3G user to re-download jsPDF even if they never use the PDF feature.

Commands contd.
du -sh dist/
1.4M

tar czf - dist | wc -c
450738

# Update package list
sudo apt update

# Install nginx, git, ufw, jq, curl
sudo apt install -y nginx git ufw jq curl

# Install Node.js LTS (v22) via NodeSource
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs

# Enable corepack (comes with Node.js 22)
sudo corepack enable

# Verify installations
node -v
npm -v
pnpm --version
nginx -v
git --version
ufw --version
jq --version
curl --version

create a system user africair with no login shell;
sudo useradd --system --no-create-home --shell /usr/sbin/nologin africair

id africair
uid=999(africair) gid=988(africair) groups=988(africair)

sudo mkdir -p /opt/africair/releases /opt/africair/shared
sudo ln -s /opt/africair/releases /opt/africair/current
sudo chown -R africair:africair /opt/africair

sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

test : sudo ufw status

# Upload
scp -i africair.pem scripts/setup-server.sh ubuntu@54.83.191.64:~/

# Make executable
ssh -i africair.pem ubuntu@54.83.191.64 "chmod +x setup-server.sh"

# First run
ssh -i africair.pem ubuntu@54.83.191.64 "./setup-server.sh"

# Second run (must change nothing, exit 0)
ssh -i africair.pem ubuntu@54.83.191.64 "./setup-server.sh"

B3.
Build.sh
git clone

 Install dependencies and build
pnpm install --frozen-lockfile
pnpm build
pnpm test

 Test Files  4 passed (4)
      Tests  30 passed | 3 skipped (33)
   Start at  20:20:30
   Duration  2.61s (transform 444ms, setup 0ms, collect 1.01s, tests 410ms, environment 1ms, prepare 421ms)

package the build as africair-<shortsha>.tar.gz plus a .sha256 checksum file;

# Write dist/version.json using jq
jq -n \
  --arg commit "$(git rev-parse HEAD)" \
  --arg ref "$GIT_REF" \
  --arg builtAt "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg builtBy "$(whoami)@$(hostname)" \
  --arg nodeVersion "$(node -v)" \
  '{commit: $commit, ref: $ref, builtAt: $builtAt, builtBy: $builtBy, nodeVersion: $nodeVersion}' \
  > dist/version.json


echo "Build complete: $BUILD_DIR"
cat dist/version.json

# Get short SHA
SHORT_SHA=$(git rev-parse --short HEAD)

# Package
tar czf "africair-${SHORT_SHA}.tar.gz" dist/

# Checksum
sha256sum "africair-${SHORT_SHA}.tar.gz" > "africair-${SHORT_SHA}.tar.gz.sha256"

# Verify
cat "africair-${SHORT_SHA}.tar.gz.sha256"
ls -lh "africair-${SHORT_SHA}.tar.gz"

why?
ln -sfn is two syscalls: unlink(current) then symlink(new-target, current)

Between them there's a gap where current doesn't exist — nginx hitting that gap serves a 502

The fix is ln -sfn ... current.new + mv -T current.new current, where mv -T uses a single rename() syscall that the kernel guarantees is atomic

sudo nginx -t || { echo "ERROR: nginx config invalid, skipping reload"; exit 50; }
sudo systemctl reload nginx

cd ~/AfricAir && git pull
sudo cp deploy/logrotate/africair /etc/logrotate.d/africair
sudo logrotate --debug /etc/logrotate.d/africair   # dry-run to verify


Healthcheck Script : Created scripts/ops/healthcheck.sh checking /healthz, /api/healthz, /version.json. Logs via logger -t africair-health. Tracks consecutive failures in /var/lib/africair/healthcheck.failures, reloads nginx after 3 failures with WARNING log entry

Systemd Service/Timer : africair-healthcheck.service (Type=oneshot, User=root) + africair-healthcheck.timer (every 1 min, OnBootSec=30, AccuracySec=5s). Service runs as root to allow systemctl reload nginx and write to /var/lib/africair/

report.sh : Created scripts/ops/report.sh — reads JSON nginx access log, prints top 10 IPs, status class breakdown, top 10 paths, requests per minute for last hour. Uses only jq, awk, sort, uniq

API Packaging : Extended scripts/deploy.sh to run pnpm build:api and package server/dist + server/migrations + prod-only node_modules as africair-api-<sha>.tar.gz. Extended scripts/ops/deploy.sh to accept optional second API artifact, deploy to /opt/africair/api/releases/<timestamp>-<sha>/, atomic symlink at /opt/africair/api/current, restart africair-api service, smoke test /api/healthz, rollback both frontend and API, prune to 5 releases

africair-api.service : Created systemd service unit for Node API. Had to manually paste it to server because git auth was failing. Service installed and enabled but not yet started

Git Auth Issue : GitHub rejected password auth on server. Fix is to use Personal Access Token in remote URL: https://<token>@github.com/ninamonopoly/AfricAir.git

Deploy Attempts : Build ran on server with pnpm install --no-frozen-lockfile (lockfile mismatch on typescript version). Tarballs created manually. Deploy rolled back because africair-api.service didn't exist yet. Service now installed, waiting to confirm git pull and start API

Files and Code Summary
scripts/deploy.sh: Clones repo, installs, tests, builds frontend + API, writes dist/version.json, packages africair-<sha>.tar.gz (frontend) and africair-api-<sha>.tar.gz (API with prod-only deps staged in temp dir)

scripts/ops/deploy.sh: Accepts <artifact> [api-artifact]. Checksums, extracts to timestamped release dirs, atomic symlink swap ( ln -sfn + mv -T), restarts africair-api, nginx reload, smoke tests, rollback both artifacts, prunes to 5 releases. Exit codes 10/20/30/40/50/60

scripts/ops/healthcheck.sh: Uses logger -t africair-health, tracks failures in /var/lib/africair/healthcheck.failures, reloads nginx at threshold 3, resets counter on success

scripts/ops/report.sh: Reads logfile arg (default /var/log/nginx/africair.access.json), four sections: top 10 IPs, status classes, top 10 paths (query strings stripped), req/min last 60 min

deploy/systemd/africair-api.service: Type=simple, User=africair, WorkingDirectory=/opt/africair/api/current, ExecStart=/usr/bin/node server/dist/index.js, EnvironmentFile=-/etc/africair/env, Restart=on-failure

deploy/systemd/africair-healthcheck.service: Type=oneshot, User=root, no SyslogIdentifier (logger handles journald directly)

deploy/systemd/africair-healthcheck.timer: OnBootSec=30, OnUnitActiveSec=1min, AccuracySec=5s

deploy/nginx/africair.conf: JSON access log, gzip, security headers, CSP (single line), immutable cache for /assets/, /healthz inline return 200, /api/ proxy to 127.0.0.1:4000, SPA fallback

server/src/migrate.ts: Reads migrations from server/migrations/*.sql, uses advisory lock, tracks applied versions in schema_migrations table, CLI entrypoint via DATABASE_URL env var

server/.env.example: Documents all env vars — PORT=4000, DATABASE_URL, ADMIN_TOKEN, PROMO_CODES, MIGRATE_ON_START, etc.

Key Insights
EC2 : Instance i-038eff2e88278998a, IP 54.83.191.64, user ubuntu, project at ~/AfricAir

GitHub : https://github.com/ninamonopoly/AfricAir, branch main, latest pushed commit 6164a8a

Git auth broken on server : Password auth rejected by GitHub. Must use PAT: git remote set-url origin https://<token>@github.com/ninamonopoly/AfricAir.git

pnpm lockfile mismatch : typescript version mismatch ( ^5.9.3 vs ^5.7.3). Workaround: pnpm install --no-frozen-lockfile on server. Proper fix: run pnpm install locally and push updated pnpm-lock.yaml

africair-api.service : Manually pasted to /etc/systemd/system/africair-api.service, daemon-reloaded, enabled. Status: inactive (dead) — not yet started

DB : PostgreSQL installed, role africair_app, database africair. Config at /etc/africair/env (chmod 600)

Deploy layout : Frontend → /opt/africair/releases/, symlink /opt/africair/current. API → /opt/africair/api/releases/, symlink /opt/africair/api/current

nginx : Running, serving /healthz correctly (returns ok). /version.json returns 404 (frontend not deployed to current). /api/healthz returns 502 (no Node process on port 4000)

Most Recent Topic
Topic : Confirming git is updated on the server to commit 6164a8a

Progress : Git pull was failing due to GitHub password auth rejection. Instructed user to generate a PAT and update remote URL. Asked user to run git -C ~/AfricAir log --oneline -3 to confirm 6164a8a is the top commit. Awaiting output.

Next steps after git confirmed :

Start the API: sudo systemctl start africair-api && sudo systemctl status africair-api

Check API release exists: ls /opt/africair/api/current/

Redeploy if needed with both artifacts

Verify: curl -s http://localhost/healthz, curl -s http://localhost/version.json, curl -s http://localhost/api/healthz

Tools Used :

fsWrite deploy/systemd/africair-api.service: Created systemd unit for Node API

fsReplace scripts/ops/deploy.sh: Changed || true to hard fail with clear error message when africair-api.service not found

executeBash git commit+push : Pushed 6164a8a with africair-api.service and deploy fix

Manual tee on server : Pasted africair-api.service content directly since git pull was failing; service enabled successfully


ls: cannot open directory '/opt/africair/api/current/': Permission denied
● africair-api.service - AfricAir API
     Loaded: loaded (/etc/systemd/system/africair-api.service; enabled; preset: enabled)
     Active: active (running) since Sat 2026-10-17 04:53:10 UTC; 26ms ago
   Main PID: 65544 (node)
      Tasks: 6 (limit: 2209)
     Memory: 2.3M (peak: 2.3M)
        CPU: 16ms
     CGroup: /system.slice/africair-api.service
             └─65544 /usr/bin/node server/dist/index.js

Oct 17 04:53:10 ip-172-31-0-48 systemd[1]: Started africair-api.service - AfricAir API.
ubuntu@ip-172-31-0-48:~/AfricAir$ 

sudo apt docker install
 added docker user
  then ran the build.

  scripts/deploy.sh: Builds frontend + API, stages prod deps, creates africair-<sha>.tar.gz and africair-api-<sha>.tar.gz with checksums. Already complete.

scripts/ops/deploy.sh: Deploys both artifacts, atomic symlinks, restarts africair-api, smoke tests, rollback, prunes to 5 releases. Already complete.

deploy/systemd/africair-api.service: Added EnvironmentFile=-/etc/africair/api.env before EnvironmentFile=-/etc/africair/env.

scripts/setup-server.sh: Added block to create /etc/africair/api.env with 6 non-secret vars, root:africair 0640, guarded by [[ ! -f ]].

config/staging.env: Non-secret settings: APP_ENV=staging, APP_VERSION=1.0.0, BRAND_NAME=AfricAir Staging, ANNOUNCEMENT_TEXT, ANNOUNCEMENT_LEVEL=warning, SERVICE_FEE_USD=5, DEFAULT_CURRENCY=NGN.

secrets.example/db_password: change-me-db-password

secrets.example/admin_token: change-me-admin-token

secrets.example/promo_codes: SAVE10:10,AFRICA20:20

docker-compose.yml: Added api service (builds from server/Dockerfile, env_file: config/staging.env, PG* vars, *_FILE secret vars, ports 4000). Updated db to use POSTGRES_PASSWORD_FILE. Updated frontend to build from root Dockerfile, depend on api. Added top-level secrets: block pointing to ./secrets/*.

Dockerfile (root): Multi-stage AfricAir frontend. Build: node:22-alpine, pnpm install --frozen-lockfile, pnpm build. Runtime: nginx:alpine, copies dist/ and deploy/nginx/docker.conf.

deploy/nginx/docker.conf: Docker-specific nginx config. Proxies /api/ to http://api:4000, SPA fallback, assets cache, /healthz inline 200.

server/Dockerfile: Multi-stage. Build: copies root package.json, pnpm-lock.yaml, pnpm-workspace.yaml, installs all deps, builds API. Runtime: copies server/dist, server/migrations, node_modules from build stage. CMD: node server/dist/index.js.

.gitignore: Added config/*.secret.env, config/.env, secrets/.

server/.env.example: Documents all env vars including *_FILE secret variants.

Key Insights
Server : EC2 instance i-038eff2e88278998a, IP 54.83.191.64, user ubuntu, project at ~/AfricAir, security group sg-0beb4ceac7618ddb0.

SSH key paths : C:/Users/Nnenna/OneDrive/Desktop/AfricAir/my-key (root) and scripts/ops/my-key.

Docker on server : Old standalone docker-compose installed; needs docker-compose-plugin for docker compose command to work properly.

Port 8080 : Open in both ufw and EC2 security group. Docker proxy confirmed listening.

Disk space : Server has very limited disk space (~5GB total). Builds fail with ENOSPC. Must run docker system prune -af --volumes before large builds.

System PostgreSQL : Conflicts with Docker db container on port 5432. Must sudo systemctl stop postgresql before starting stack.

pnpm workspace : Root pnpm-lock.yaml must be copied into Docker build context; server Dockerfile copies from root workspace.

GitHub repo : https://github.com/ninamonopoly/AfricAir, branch main.

Most Recent Topic
Topic : Installing docker-compose-plugin to fix KeyError: 'ContainerConfig' bug in old standalone docker-compose, then getting AfricAir frontend running at http://54.83.191.64:8080.

Progress :

Old docker-compose (standalone, Python-based) threw KeyError: 'ContainerConfig' when trying to recreate containers.

Instructed user to install docker-compose-plugin and use docker compose (with space) instead.

Prior to this, fixed frontend to serve AfricAir Vite app (not employee app) by creating root Dockerfile and deploy/nginx/docker.conf.

Disk space issues repeatedly interrupted builds; freed via docker system prune and snap removal.

Stack not yet confirmed running successfully at http://54.83.191.64:8080.

Tools Used :

fsRead docker-compose.yml, server/.env.example, .gitignore, deploy/systemd/africair-api.service, frontend/Dockerfile, deploy/nginx/africair.conf, server/Dockerfile, server/package.json: Read existing configs to understand structure.

fsWrite config/staging.env: Created non-secret staging settings.

fsWrite secrets.example/db_password, admin_token, promo_codes: Created dummy secret files.

fsWrite Dockerfile: Created AfricAir root frontend Dockerfile.

fsWrite deploy/nginx/docker.conf: Created Docker-specific nginx config proxying to api service.

fsWrite server/Dockerfile: Created multi-stage API Dockerfile.

fsReplace docker-compose.yml: Added api service, secrets, updated frontend and db services.

fsReplace .gitignore: Added secrets/ and config secret patterns.

fsReplace deploy/systemd/africair-api.service: Added api.env EnvironmentFile.

fsReplace scripts/setup-server.sh: Added /etc/africair/api.env creation block.

executeBash mkdir config, secrets, secrets.example: Created directories.

---

## Docker Module (Project 2)

### Stack

- `docker-compose.yml`: Three services — `db` (postgres:15), `api` (Node.js, builds from `server/Dockerfile`), `frontend` (Vite/React, builds from root `Dockerfile`).
- `Dockerfile` (root): Multi-stage. Build stage: node:22-alpine, `pnpm install --frozen-lockfile`, `pnpm build`. Runtime stage: nginx:alpine, serves `dist/` with `deploy/nginx/docker.conf`.
- `server/Dockerfile`: Multi-stage. Copies root workspace files, builds API, runtime stage runs `node server/dist/index.js`.
- `deploy/nginx/docker.conf`: Proxies `/api/` to `http://api:4000`, SPA fallback, assets cache, `/healthz` inline 200.
- `config/staging.env`: Non-secret env vars (APP_ENV, BRAND_NAME, SERVICE_FEE_USD, DEFAULT_CURRENCY, etc.).
- `secrets/`: Runtime secret files (not committed). `secrets.example/` has dummy values for reference.

### Issues encountered and fixes

- **Old `docker-compose` (standalone 1.29.2)**: Threw `KeyError: 'ContainerConfig'` bug. Fix: install `docker-compose-plugin` and use `docker compose` (with space).
- **`docker compose` not found after plugin install**: Docker daemon wasn't running. Fix: `sudo systemctl start docker && sudo systemctl enable docker`.
- **Disk full (ENOSPC)**: 6.8 GB root volume repeatedly filled during builds. Fix: `docker system prune -af --volumes`, `sudo apt-get clean`, removed snap packages. Long-term fix: resize EC2 volume to 20 GB via AWS Console, then `sudo growpart /dev/nvme0n1 1 && sudo resize2fs /dev/root`.
- **Port 5432 already in use**: System PostgreSQL conflicted with Docker `db` container. Fix: `sudo systemctl stop postgresql && sudo systemctl disable postgresql`.
- **Frontend serving employee app instead of AfricAir**: Server's `docker-compose.yml` had `build: ./frontend` (old path). Root `Dockerfile` was never committed. Fix: committed `Dockerfile` and `deploy/nginx/docker.conf`, pushed, pulled on server, removed stale image with `docker rmi africair-frontend:latest`, rebuilt.
- **`docker-compose-plugin` install failed (disk full)**: Freed space first with `docker system prune`, then retried install.

### Commands run

```bash
# Add Docker apt repo and install compose plugin
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update && sudo apt-get install -y docker-compose-plugin

# Free disk space
docker system prune -af --volumes
sudo apt-get clean
sudo rm -rf /var/cache/apt/archives/*.deb

# Stop conflicting system PostgreSQL
sudo systemctl stop postgresql
sudo systemctl disable postgresql

# Start Docker daemon
sudo systemctl start docker
sudo systemctl enable docker

# Bring stack up
cd ~/AfricAir
git pull
docker compose down
docker rmi africair-frontend:latest
docker compose up -d --build
```

### Verification

```bash
docker compose ps
curl -s http://localhost:8080 | grep -i "<title>"
curl -s http://localhost:4000/api/healthz
```

AfricAir frontend running at `http://54.83.191.64:8080`.


---

## Static Hosting on S3 + CloudFront

### Infrastructure (Terraform)

**terraform/main.tf** — added `aws_s3_bucket_server_side_encryption_configuration`:
- Algorithm: AES256 (SSE-S3), bucket_key_enabled = true
- Bucket has Block Public Access all four flags = true (was already present)
- Versioning enabled (was already present)

**terraform/cloudfront.tf** — new file:
- `aws_cloudfront_origin_access_control` — signs S3 requests with SigV4 (signing_behavior = always)
- `aws_cloudfront_response_headers_policy` — B5 security headers on every response:
  - X-Content-Type-Options: nosniff
  - X-Frame-Options: SAMEORIGIN
  - Referrer-Policy: strict-origin-when-cross-origin
  - Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data:; connect-src 'self'; frame-ancestors 'none'
  - Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
- `aws_cloudfront_distribution` — viewer_protocol_policy = redirect-to-https, default_root_object = index.html, SPA custom_error_response (403/404 → index.html)
- `aws_s3_bucket_policy` — AllowCloudFrontOAC: allows cloudfront.amazonaws.com s3:GetObject only where AWS:SourceArn = this distribution ARN

**terraform/deployer-iam.tf** — least-privilege deployer IAM user:
- s3:ListBucket on bucket ARN (bucket-level, no /*)
- s3:PutObject + s3:DeleteObject on bucket/* (object-level)
- cloudfront:CreateInvalidation on distribution ARN only

**terraform/outputs.tf** — added: cloudfront_domain, cloudfront_distribution_id, cloudfront_distribution_arn, deployer_user_arn, deployer_policy_arn

Bucket names renamed from `landmark` → `africair` (all envs: dev, stg, prod)
State bucket: `africair-terraform-state-075120018043`
App bucket: `africair-app-bucket-dev`

### Deploy Scripts

**scripts/ops/publish-s3.sh** and **scripts/ops/Publish-S3.ps1** (PowerShell for Windows):

Deploy order and why it matters:
1. `aws s3 sync assets/ → s3://bucket/assets/` with `Cache-Control: public,max-age=31536000,immutable`
   — Assets must exist before index.html goes live; hashed names never collide
2. `aws s3 cp index.html` with `Cache-Control: no-cache`
   — Only after assets are live; index.html names the new asset filenames
3. `aws s3 cp version.json` with `Cache-Control: no-cache`
4. `aws s3 sync --delete` — removes stale files LAST; browsers with cached old index.html still need old assets until new index.html propagates
5. `aws cloudfront create-invalidation --paths "/index.html" "/version.json"` — never `/*`

Why not `/*`:
- Hashed assets are correct by filename — old name and new name are different objects, no invalidation needed
- `/*` evicts the entire edge cache globally → every user takes a cold miss → origin load spike
- AWS charges per invalidation path after 1,000/month free

**scripts/ops/test-deployer-permissions.sh** — proves least-privilege:
- ✅ ListBucket on own bucket → allowed
- ✅ PutObject probe file → allowed
- ✅ DeleteObject probe file → allowed
- ❌ ListBucket on different bucket → AccessDenied
- ❌ GetObject on own bucket → AccessDenied (deployer can write but not read)
- ❌ CreateInvalidation on different distribution → AccessDenied

### E2E Results Against CloudFront

URL: https://d32p393pvdyujd.cloudfront.net
Distribution ID: ERTERJ4EGO84I

Command: `$env:BASE_URL="https://d32p393pvdyujd.cloudfront.net"; pnpm test:e2e --grep "booking"`

Result: **12/14 passed**

2 expected failures — "complete round-trip booking with mixed travellers, PDF and My trips":
- Test tries to save booking to database via /api/bookings → ERR_CONNECTION_RESET (no backend behind CloudFront)
- This is correct behaviour for static hosting; My trips requires the Node API

Fix applied to e2e/booking.spec.ts: pageerror listener now filters ERR_CONNECTION_RESET (expected in static mode, same as the existing /api/ filter on the console listener)

### Why S3 Can Never Keep a Secret

S3 stores files. Every file it serves is a URL the browser downloads. Even with Block Public Access on, anything the browser receives is readable in DevTools.

A secret is only secret if it never leaves the server process. On EC2:
- ADMIN_TOKEN lives in /etc/africair/env, loaded into the Node process environment
- The browser sends a token the user typed; Node compares it in memory; nothing secret crosses the wire

On S3/CloudFront:
- Any value in a downloaded file (JS, JSON, HTML) is readable by anyone with DevTools
- Credentials, database passwords, promo code lists, admin tokens must live on a compute layer (EC2, ECS, Lambda), never in a static file

### Features Missing in Static Mode vs EC2

| Feature | CloudFront (static) | EC2 (full stack) |
|---|---|---|
| Flight search + booking | ✅ | ✅ |
| PDF itinerary | ✅ | ✅ |
| Promo codes | ❌ disabled | ✅ server-validated |
| My trips (save/retrieve) | ❌ browser only | ✅ database |
| Cancel booking | ❌ browser only | ✅ persisted |
| Admin dashboard | ❌ 404 | ✅ behind ADMIN_TOKEN |
| Maintenance mode | ❌ can't change | ✅ live from API |
| Announcements/banners | ❌ can't change | ✅ live from API |
| Secrets status page | ❌ hidden | ✅ shows db/token state |
| Service fee config | ❌ hardcoded $15 | ✅ operator-configurable |

### S3 Public Access Verification

```
aws s3api get-public-access-block --bucket africair-app-bucket-dev --profile terraform
{
    "PublicAccessBlockConfiguration": {
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }
}
```

All four flags true ✅ — direct S3 URL returns 403 Access Denied; only CloudFront OAC can read objects.

### Branch

`feat/s3-cloudfront-static-hosting` — commits:
- `2db5bc6` S3 encryption + CloudFront Terraform
- `7dc7f49` publish-s3.sh deploy script
- `e9d6abf` deployer IAM policy + proof script
- `300b714` rename buckets landmark → africair
- `6bc2622` Publish-S3.ps1 PowerShell script


---

## Docker Containerisation

### Dockerfile changes

**OCI image labels** — added as `ARG` + `LABEL` in the runtime stage:
```
org.opencontainers.image.revision  = GIT_SHA build-arg
org.opencontainers.image.version   = VERSION build-arg
org.opencontainers.image.created   = BUILD_DATE build-arg (ISO 8601)
org.opencontainers.image.source    = SOURCE_URL build-arg
```
Pass at build time:
```powershell
$GIT_SHA = git rev-parse HEAD
$BUILD_DATE = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
docker build --build-arg GIT_SHA=$GIT_SHA --build-arg VERSION=1.0.0 --build-arg BUILD_DATE=$BUILD_DATE -t africair:latest .
```

**HEALTHCHECK** — uses BusyBox `wget` (available in `nginx:alpine`):
```
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --spider --quiet http://localhost:8080/healthz || exit 1
```
- `--spider`: HEAD-only request, no body downloaded
- `start-period=5s`: gives nginx time to start before failures count
- `retries=3`: 3 consecutive failures = container marked unhealthy

**EXPOSE 8080** — changed from 80. nginx now listens on 8080 (non-root port convention).

**Template instead of static config** — `COPY deploy/nginx/templates/ /etc/nginx/templates/` replaces the old static `docker.conf` copy. nginx:alpine's entrypoint runs envsubst on `*.template` files at startup.

### nginx envsubst template

File: `deploy/nginx/templates/default.conf.template`

Variables substituted at container startup:
- `${API_UPSTREAM}` → e.g. `http://api:4000`
- `${APP_ENV}` → e.g. `staging`, `production`

nginx's own `$variables` (`$host`, `$remote_addr`, etc.) are left untouched.

Features in the template:
- `listen 8080`
- gzip (JS, CSS, JSON, SVG, text)
- Security headers: X-Content-Type-Options, X-Frame-Options, Referrer-Policy, CSP (always)
- `X-Environment: ${APP_ENV}` response header
- `/healthz` — 200 ok, access_log off
- `/assets/` — `Cache-Control: public, max-age=31536000, immutable`
- `/index.html` and `/version.json` — `Cache-Control: no-cache`
- `/api/` proxy to `${API_UPSTREAM}` with X-Forwarded-For
- SPA fallback `/` → index.html

### docker-compose.yml changes

- `frontend` service: added `API_UPSTREAM: http://api:4000` and `APP_ENV: staging`
- `frontend` ports: `8080:80` → `8080:8080` (matches nginx listen port)
- `db` ports mapping removed — host PostgreSQL was occupying 5432; the api container reaches db via Docker's internal network, no host port needed

### Port conflict on EC2

Host PostgreSQL was running on port 5432. Docker tried to bind `0.0.0.0:5432` for the db container → `address already in use`. Fix: removed the db `ports:` mapping from docker-compose.yml. The api container still reaches db at `db:5432` via the Docker bridge network.

### Build command (PowerShell / Windows)

```powershell
$GIT_SHA = git rev-parse HEAD
$BUILD_DATE = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
docker build `
  --build-arg GIT_SHA=$GIT_SHA `
  --build-arg VERSION=1.0.0 `
  --build-arg BUILD_DATE=$BUILD_DATE `
  --build-arg SOURCE_URL=https://github.com/ninamonopoly/AfricAir `
  -t africair:latest .
```

### Verify labels and health

```bash
docker inspect africair:latest --format '{{json .Config.Labels}}' | jq
docker compose up -d
curl -sI http://localhost:8080/ | grep -i x-environment   # → X-Environment: staging
curl -s http://localhost:8080/healthz                      # → ok
docker ps --format "table {{.Names}}\t{{.Status}}"        # → (healthy) after ~35s
```


---

## Dockerfile.api -- multi-stage API image

File: `Dockerfile.api` (repo root). Builds only the `@africair/api` package.

### Stages

| Stage | Purpose | Contents |
|---|---|---|
| `build` | Install workspace deps, run `pnpm build:api` | full node_modules incl. tsc/tsx, compiled `dist/` |
| `prod-deps` | Production-only node_modules | `pnpm deploy --filter=@africair/api --prod --legacy /prod/api` -- drops typescript, tsx, @types |
| `runtime` | Shippable image | `node:22-alpine`, `dist/`, `migrations/`, `package.json`, prod node_modules, `USER node` |

### Key decisions

- **`pnpm deploy --prod`** resolves the workspace package's real dependency tree
  into one flat, self-contained folder (no store symlinks). `--prod` omits all
  devDependencies, so TypeScript, tsx and the type packages never ship.
  `--legacy` is required for a workspace deploy on pnpm 10.
- **`USER node`** -- the image runs unprivileged; the `node` user ships with the
  base image.
- **`EXPOSE 4000 9464`** -- API port and Prometheus metrics port.
- **HEALTHCHECK** -- BusyBox `wget --spider` on `/api/healthz`, every 30s.
- **`CMD ["node", "dist/index.js"]`** -- Node runs as PID 1 directly. Not
  `pnpm start`: pnpm would fork node as a child, so `docker stop`'s SIGTERM
  would hit pnpm and never reach node, breaking graceful shutdown and leaving
  node without PID-1 zombie-reaping.
- **Migrations use the same image**: `docker run --rm africair-api node dist/migrate.js`.

### Build

```bash
docker build -f Dockerfile.api \
  --build-arg GIT_SHA=$(git rev-parse HEAD) \
  --build-arg VERSION=1.0.0 \
  --build-arg BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ) \
  -t africair-api:latest .
```

### Image size: ~148 MB (over the 120 MB target -- base image is the floor)

| Layer | Size | What it is |
|---|---|---|
| `node:22-alpine` base | ~135 MB | Node 22 runtime + Alpine libc -- the unavoidable floor |
| prod node_modules | ~8-12 MB | `pg` + `prom-client` and their small deps |
| `dist/` + `migrations/` | < 1 MB | compiled JS + one SQL file |
| **Total** | **~148 MB** | |

**What the remaining megabytes are:** the Node runtime itself. `node:22-alpine`
is already the slim variant; our own code and deps add barely 10 MB. The only
way under 120 MB is a distroless Node base (~115 MB), which has no shell, so the
healthcheck would have to call `node` instead of `wget`. We chose to keep alpine
for the working shell and BusyBox `wget` healthcheck, and accept ~148 MB.


---

## Docker Compose staging stack — verification runbook

Bring up the serving stack (no Playwright, light on RAM):

```bash
cd ~/AfricAir
docker compose -f compose.yaml up --build -d db migrate api web
```

All browser checks are at `http://localhost:8080`.

### 1. Settings come from config/staging.env
- Home: orange **STAGING** banner, announcement "You are on the Docker Compose
  staging stack", brand **AfricAir Staging**, prices in **NGN**.
- Review page: **AfricAir service fee $5** (`SERVICE_FEE_USD=5`).

### 2. /#/status
- Storage: **PostgreSQL database**.
- db_password / admin_token / promo_codes each **Configured · source: file**.

### 3. Promo + admin
- Book a flight, apply **SAVE10** → discount shows in the fare and in the PDF.
- `/#/admin` + the admin token value → the booking is listed.

### 4. Maintenance mode
```bash
sed -i 's/^MAINTENANCE_MODE=.*/MAINTENANCE_MODE=true/' config/staging.env \
  || echo "MAINTENANCE_MODE=true" >> config/staging.env
docker compose -f compose.yaml up -d api      # RECREATE api with the new env
```
Booking is blocked ("Bookings are paused for maintenance").

**Why `docker compose restart` is NOT enough after editing an env file:**
`env_file` is read only when a container is **created**, and the values are
baked into that container's environment at creation. `restart` stops and starts
the *same* container with the *same* frozen env — it never re-reads the file.
`up -d api` **recreates** the container, taking a fresh snapshot of the edited
file. restart = same env; up = new container, new env.

### 5. Rotate the admin token with NO restart
```bash
echo "new-admin-token-value" > secrets/admin_token
```
Within `SECRET_REFRESH_SECONDS` (10s): the fingerprint on `/#/status` changes,
the old token gives "Invalid admin token", the new one works. The API's
`secretReader` re-reads `*_FILE` secrets every 10s, so a rotated file secret is
picked up live — an env-var secret would need a restart.

### 6. Stop db → graceful failure and recovery
```bash
docker compose -f compose.yaml stop db
curl -s localhost:8080/api/readyz          # 503
# /#/status shows the database error; booking fails with a clear message
docker compose -f compose.yaml start db
curl -s localhost:8080/api/readyz          # 200 again — api NOT restarted
```
The connection pool reconnects on its own; api recovers without a restart.

### 7. No secret values in the api environment
```bash
docker compose -f compose.yaml exec api env | grep -i token
# -> ADMIN_TOKEN_FILE=/run/secrets/admin_token   (a PATH, never the value)
```

**Why `*_FILE` secrets are safer than env-var secrets:**
- **`docker inspect`** prints a container's env vars in plain text — an env-var
  secret is readable by anyone who can inspect the container. A `_FILE` var only
  exposes a path.
- **`/proc/<pid>/environ`** holds a running process's full environment on disk;
  any user who can read it (same UID or root) sees every env-var secret. A file
  secret is never in the environment — it lives at a permissioned path.
- **Crash dumps / logs**: core dumps and many error/logging frameworks capture
  the whole environment block, so env-var secrets leak into dump files and log
  aggregators. A path leaks nothing.

In short: an env var is broadcast to inspect, `/proc`, child processes and crash
dumps; a file secret is read on demand from a permissioned path and can be
rotated in place without a restart.


---

## Container hardening (api + web)

Both app containers run locked down. The required `docker run` flags map to
Compose service keys as follows:

| `docker run` flag | Compose key | Effect |
|---|---|---|
| `--read-only` | `read_only: true` | root filesystem is immutable |
| `--tmpfs /tmp` | `tmpfs: [/tmp]` | only writable path, in RAM, wiped on stop |
| `--cap-drop ALL` | `cap_drop: [ALL]` | drops every Linux capability |
| `--security-opt no-new-privileges` | `security_opt: [no-new-privileges:true]` | a child process can never gain more privileges than its parent |
| `--memory 128m` | `mem_limit: 128m` | OOM-killed past 128 MB |
| `--cpus 0.5` | `cpus: 0.5` | at most half a core |
| `--pids-limit 100` | `pids_limit: 100` | caps processes (fork-bomb guard) |

### Why web needs extra tmpfs mounts

A read-only root still has to let nginx write three runtime paths, so each is a
small in-memory tmpfs:

- `/var/cache/nginx` — proxy/temp caches
- `/var/run` — `nginx.pid`
- `/etc/nginx/conf.d` — envsubst writes the processed template here at startup

Without these, nginx fails to start under `read_only: true`. The API writes
nothing but `/tmp`.

### Verify the hardening is active

```bash
docker inspect africair-api-1 --format \
  '{{.HostConfig.ReadonlyRootfs}} {{.HostConfig.CapDrop}} {{.HostConfig.Memory}} {{.HostConfig.PidsLimit}}'
# -> true [ALL] 134217728 100
```

### Note on the 128 MB limit

Node with only `pg` + `prom-client` fits in 128 MB, but it is tight. If the api
container exits 137 (SIGKILL/OOM) it is the memory limit biting, not a
misconfiguration — raise `mem_limit` only if the real footprint demands it.


### Root cause: why the web container breaks under `--read-only` (envsubst)

**Symptom.** With `read_only: true`, the web container exits immediately at
startup instead of serving.

**Root cause.** The `nginx:alpine` entrypoint (`docker-entrypoint.sh`) runs
`envsubst` over every `/etc/nginx/templates/*.template` at boot and **writes the
rendered result into `/etc/nginx/conf.d/`** (default
`NGINX_ENVSUBST_OUTPUT_DIR=/etc/nginx/conf.d`). A read-only root filesystem
refuses that write, so the entrypoint fails before nginx ever loads a config and
the container dies.

```
read-only root  ->  entrypoint envsubst writes /etc/nginx/conf.d/default.conf  ->  EROFS  ->  crash
```

**Fix (keeps `--read-only`).** Make only that one output directory writable by
mounting it as an in-memory tmpfs — the root stays immutable:

```yaml
read_only: true
tmpfs:
  - /etc/nginx/conf.d   # envsubst renders the template here at startup
  - /var/cache/nginx    # proxy/temp caches
  - /var/run            # nginx.pid
```

**Alternative fix (the hint).** Instead of making the default folder writable,
redirect the output with `NGINX_ENVSUBST_OUTPUT_DIR` to a path that is already
writable (e.g. a tmpfs'd `/tmp/conf.d`) and `include` it. Either fix works; this
stack uses the tmpfs-the-default-folder approach above, so no env var is needed.

**Why not just drop `--read-only`?** That would let any process write anywhere
in the container — exactly the attack surface the hardening is meant to remove.
The point is to allow the *one* write nginx genuinely needs and freeze the rest.
