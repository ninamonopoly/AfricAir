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


