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

pnpm install --frozen-lockfile
ubuntu@ip-172-31-0-48:~$ pnpm install --frozen-lockfile
Already up to date
Done in 194ms using pnpm v12.11.2

Error: ERR_PNPM_RECURSIVE_EXEC_FIRST_FAIL

  × Command "check" not found


## Linux Server Setup

### Security group SSH rule
```bash
aws ec2 authorize-security-group-ingress \
  --region us-east-1 \
  --group-id sg-0beb4ceac7618ddb0 \
  --ip-permissions IpProtocol=tcp,FromPort=22,ToPort=22,PrefixListIds='[{PrefixListId=pl-0e4bcff02b13bef1e}]'
```
Allows inbound SSH only from the EC2 Instance Connect IP ranges for us-east-1 via a managed prefix list. AWS keeps the list current automatically — no manual rule updates needed.

### UFW
UFW (Uncomplicated Firewall) is an iptables frontend. It acts as an OS-level firewall on the server itself, complementing the AWS Security Group (cloud-level). Both must allow traffic for a connection to succeed.

### Why plain ln -sfn is not atomic

`ln -sfn` is implemented as two separate syscalls:
1. `unlink(current)` — removes the existing symlink
2. `symlink(new-target, current)` — creates the new one

Between those two syscalls there is a window where `current` does not exist. If nginx resolves the symlink at that exact moment (e.g. during a reload), it gets a "no such file" error and serves a 502 to users.

The atomic alternative:
```bash
ln -sfn /opt/africair/releases/20250714T102530Z-abc1234 /opt/africair/current.new
mv -T /opt/africair/current.new /opt/africair/current
```
`mv -T` calls the `rename()` syscall, which the Linux kernel guarantees is atomic — `current` always points to either the old or the new release, never nothing. No 502 window.

### Idempotent setup script
The full setup is in `scripts/setup-server.sh`. A second run changes nothing and exits 0 because:
- `apt-get install -y` skips already-installed packages
- `command -v node` guards the NodeSource install
- `id africair` guards the useradd
- `[ ! -L /opt/africair/current ]` guards the symlink creation
- `ufw allow` on an existing rule is a no-op
- `ufw --force enable` on an already-enabled firewall is a no-op

## nginx (`deploy/nginx/africair.conf`)

### Cache-Control strategy
- `/assets/*` — `Cache-Control: public, max-age=31536000, immutable`. Vite's content-hashed filenames mean these files never change; browsers and CDNs can cache them forever.
- `/index.html` and `/version.json` — `Cache-Control: no-cache`. The browser revalidates on every request but can still serve from cache on a 304. `index.html` must always be fresh so the browser loads the correct hashed asset filenames after a deploy. `version.json` is smoke-tested on every deploy so it must never be stale.

### /healthz
Served inline by nginx (`return 200 "ok\n"`), never proxied to Node. `access_log off` keeps load-balancer and smoke-test probes out of the access log.

### Security headers
- `X-Content-Type-Options: nosniff` — prevents browsers from MIME-sniffing a response away from the declared content type.
- `X-Frame-Options: SAMEORIGIN` — blocks the page being embedded in a frame on another origin (clickjacking).
- `Referrer-Policy: strict-origin-when-cross-origin` — sends the full URL as referrer on same-origin requests, only the origin on cross-origin, nothing on downgrade to HTTP.
- `Content-Security-Policy` — restricts what the browser may load:
  - `default-src 'self'` — catch-all; blocks everything not explicitly listed.
  - `script-src 'self'` — all JS is self-hosted hashed assets; no inline scripts or CDN.
  - `style-src 'self' https://fonts.googleapis.com` — the CSS `@import` in `styles.css` fetches the Google Fonts stylesheet from `fonts.googleapis.com`.
  - `font-src 'self' https://fonts.gstatic.com` — the actual `.woff2` font files are served from `fonts.gstatic.com`.
  - `img-src 'self' data:` — SVG mark is self-hosted; `data:` covers any base64-encoded images.
  - `connect-src 'self'` — all API calls go to `/api/` on the same origin.
  - `frame-ancestors 'none'` — blocks framing entirely (supersedes `X-Frame-Options` in modern browsers).

### Gzip
Enabled for `text/css`, `application/javascript`, `application/json`, and `image/svg+xml` with a 1 KB minimum. nginx always compresses `text/html` by default.

### JSON access log
`log_format africair_json escape=json` writes one JSON object per line to `/var/log/nginx/africair.access.json`. `escape=json` (nginx ≥ 1.11.8) automatically escapes special characters so the output is always valid JSON. Consumable directly with `jq`, CloudWatch Logs, or Loki.

### ops/deploy.sh additions
- **Smoke tests**: after `systemctl reload nginx`, the script curls `/healthz` (must return 200) and `/version.json` (commit field must match the artifact SHA).
- **Auto-rollback**: if either check fails, the previous release symlink is restored atomically and nginx is reloaded; the script exits 60.
- **Release pruning**: after a successful deploy, `ls -1dt releases/*/` sorted newest-first; `tail -n +6` yields everything beyond the 5 most recent; each is `rm -rf`'d unless it is the current live release.

### logrotate (`deploy/logrotate/africair`)
Install: `sudo cp deploy/logrotate/africair /etc/logrotate.d/africair`
- `daily` / `rotate 14` — keeps 14 days of logs.
- `compress` / `delaycompress` — gzips rotated files; `delaycompress` leaves the most recently rotated file uncompressed for one day so it can be read immediately after rotation.
- `missingok` — no error if the log file doesn't exist yet.
- `notifempty` — skips rotation on an empty file.
- `postrotate: nginx -s reopen` — tells nginx to close the old file handle and open a fresh one at the same path; without this nginx would keep writing to the renamed rotated file.
