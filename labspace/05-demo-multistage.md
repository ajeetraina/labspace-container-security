# Demo #3 — BP#2: Multi-Stage Builds

> **Best Practice #2:** Use multi-stage builds to keep prod images clean.
> Dev tools, compilers, and test frameworks stay out of production.

## What must NOT ship to production

- Source code (after copy/compile)
- IDE tooling and editors
- Compilers and build tools
- Debuggers
- `npm install` full set (includes devDependencies)
- Non-deployable build artifacts

## Examine the Dockerfile structure

Open :fileLink[Dockerfile]{path="catalog-service-node/Dockerfile" line=1}. Three stages:

```none no-copy-button
FROM node:25-slim AS base     <-- shared foundation
  └─ FROM base AS dev          <-- installs ALL deps + dev tools
  └─ FROM base AS final        <-- npm ci --production only
```

The critical production line:

```dockerfile no-copy-button
RUN npm ci --production --ignore-scripts && npm cache clean --force
```

- `--production` — only production dependencies, devDeps excluded
- `--ignore-scripts` — no post-install scripts (a common supply chain attack vector)
- `npm cache clean --force` — removes cache from the layer, shrinks image

## Build specific stages

Dev stage only:

```bash terminal-id=build
docker build -t catalog-service:dev --target dev .
```

Production stage only:

```bash terminal-id=build
docker build -t catalog-service:prod --target final .
```

```bash terminal-id=build
docker images catalog-service
```

The `dev` image is larger (all devDependencies). The `prod` image is lean —
smaller attack surface, faster pulls.

## Why `--ignore-scripts` matters

```bash terminal-id=build
docker scout cves catalog-service:prod --only-severity critical,high --org $$org$$
```

Post-install scripts are a well-known supply chain attack vector (the `node-ipc`
incident in 2022 exploited this). `--ignore-scripts` prevents them from running
during `npm ci`.
