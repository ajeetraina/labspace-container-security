# Demo #8 — Migrate to Docker Hardened Images

> **The proactive approach: Start Secure.**
> DHI images are purpose-built from the ground up to be extremely minimal —
> not stripped-down versions of something bloated.

## DHI variants

| Variant | Tag pattern | Use case |
|---------|-------------|----------|
| Dev | `$$dhiPrefix$$node:24-debian13-dev` | Building — has shell, npm |
| Runtime | `$$dhiPrefix$$node:24-debian13` | Production — distroless, no shell |

Because the runtime variant has no shell or `npm`, we use **multi-stage builds**:
the dev image installs dependencies, the runtime image gets only the output.

## Update the Dockerfile

Open :fileLink[Dockerfile]{path="catalog-service-node/Dockerfile"} and save:

```yaml save-as=catalog-service-node/Dockerfile
###########################################################
# Stage: base (DHI dev variant — has shell + npm for builds)
###########################################################
FROM $$dhiPrefix$$node:24-debian13-dev AS base

WORKDIR /usr/local/app
COPY package.json package-lock.json ./

###########################################################
# Stage: dev
###########################################################
FROM base AS dev
ENV NODE_ENV=development
RUN npm install
CMD ["yarn", "dev-container"]

###########################################################
# Stage: production-dependencies
###########################################################
FROM base AS production-dependencies
ENV NODE_ENV=production
RUN npm ci --production --ignore-scripts && npm cache clean --force

###########################################################
# Stage: final (DHI runtime — distroless, no shell)
###########################################################
FROM $$dhiPrefix$$node:24-debian13 AS final
ENV NODE_ENV=production
COPY --from=production-dependencies /usr/local/app/node_modules ./node_modules
COPY ./src ./src
EXPOSE 3000
CMD ["node", "src/index.js"]
```

```diff no-copy-button
- FROM node:25-slim AS base
+ FROM $$dhiPrefix$$node:24-debian13-dev AS base   # build stage
+ FROM $$dhiPrefix$$node:24-debian13 AS final      # runtime — distroless
```

## Build the DHI version

```bash terminal-id=build
docker build -t catalog-service:dhi --sbom=true --provenance=mode=max .
```

## Compare all three images

```bash terminal-id=build
docker images catalog-service
```

```none no-copy-button
IMAGE                    ID             DISK USAGE   CONTENT SIZE
catalog-service:dhi      ac3a0d465de4        191MB         40.3MB
catalog-service:latest   48806e62b871       1.62GB          413MB
catalog-service:slim     8d03cef7a79f        368MB         84.1MB
```

## Scout quickview — all 7 policies green

```bash terminal-id=build
docker scout quickview catalog-service:dhi --org $$org$$
```

```none no-copy-button
Target     │  catalog-service:dhi  │    0C     0H     0M     0L

Policy status  SUCCEEDED  (7/7 policies met)

  Status │                              Policy                              │  Results
─────────┼──────────────────────────────────────────────────────────────────┼──────────
  ✓      │ Default non-root user                                            │
  ✓      │ No AGPL v3 licenses                                              │
  ✓      │ No fixable critical or high vulnerabilities                      │
  ✓      │ No high-profile vulnerabilities                                  │
  ✓      │ No unapproved base images                                        │
  ✓      │ Supply chain attestations                                        │
  ✓      │ No outdated base images                                          │
```

**7/7 policies met.** Up from 4/7 at the start.

## Full before/after comparison

```bash terminal-id=build
docker scout compare \
    --ignore-unchanged \
    --to catalog-service \
    catalog-service:dhi \
    --org $$org$$
```

```none no-copy-button
  vulnerabilities │  0C  0H  0M  0L   │  2C  26H  25M  122L  4?
  size            │  40 MB (-358 MB)   │  398 MB
  packages        │  211 (-595)        │  806
```

- **595 packages removed** — 595 fewer potential CVE vectors
- **179 vulnerabilities removed** across all severities
- Image is **10x smaller**

## The no-shell demo

Because the DHI runtime is distroless, an attacker who gains code execution
**cannot drop to a shell**:

```bash terminal-id=build
docker run --rm catalog-service:dhi sh
```

Expected: error — `sh` does not exist in the image.

Compare to slim:

```bash terminal-id=build
docker run --rm catalog-service:slim sh -c "echo 'shell available — attack surface'"
```

## DHI vs slim — property comparison

| Property | `node:25-slim` | DHI runtime |
|----------|---------------|-------------|
| CVEs (critical/high) | 2H | 0C 0H |
| Package count | ~272 | ~12 |
| Shell in runtime | Yes (`sh`) | No (distroless) |
| Non-root by default | Manual | Built-in |
| SBOM | Build-time only | Cryptographically signed |
| VEX document | No | Yes |
| SLSA provenance | Build-time only | Verified |
| FIPS variant | No | Yes (`-fips` tag) |
| STIG variant | No | Yes |
| 7-day CVE SLA | No | Yes |
