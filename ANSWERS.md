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



