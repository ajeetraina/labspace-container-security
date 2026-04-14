# Demo #2 — BP#1: Minimal Base Images

> **Best Practice #1:** Start with minimal base images.
> Less OS surface = fewer CVEs = smaller attack window.

## The comparison at a glance

| Image | Size | Packages | CVEs |
|-------|------|----------|------|
| `node:25` (full) | 1.63 GB | 693 | 242 |
| `node:lts-slim` | 344 MB | ~272 | 34 |
| `node:25-slim` | 322 MB | 272 | 30 |
| `node:alpine` | 239 MB | ~150 | 34 |
| `dhi.io/node:25` | ~50 MB | 1 | 7\* |

> \*6 of 7 have upstream fixes pending. 0 critical, 0 high.

## Update the Dockerfile base image

Open :fileLink[Dockerfile]{path="catalog-service-node/Dockerfile" line=8} and save:

```yaml save-as=catalog-service-node/Dockerfile
###########################################################
# Stage: base
###########################################################
FROM node:25-slim AS base

WORKDIR /usr/local/app
RUN useradd -m appuser && chown -R appuser /usr/local/app
USER appuser
COPY --chown=appuser:appuser package.json package-lock.json ./

###########################################################
# Stage: dev
###########################################################
FROM base AS dev
ENV NODE_ENV=development
RUN npm install
CMD ["yarn", "dev-container"]

###########################################################
# Stage: final
###########################################################
FROM base AS final
ENV NODE_ENV=production
RUN npm ci --production --ignore-scripts && npm cache clean --force
COPY ./src ./src

EXPOSE 3000

CMD [ "node", "src/index.js" ]
```

```diff no-copy-button
- FROM node:18 AS base
+ FROM node:25-slim AS base
```

## Rebuild and re-scan

```bash terminal-id=build
docker build -t catalog-service:slim --sbom=true --provenance=mode=max .
```

```bash terminal-id=build
docker images catalog-service
```

```none no-copy-button
IMAGE                    ID             DISK USAGE   CONTENT SIZE
catalog-service:latest   48806e62b871       1.62GB          413MB
catalog-service:slim     8d03cef7a79f        368MB         84.1MB
```

```bash terminal-id=build
docker scout quickview catalog-service:slim --org $$org$$
```

```none no-copy-button
  Target             │  catalog-service:slim  │    0C     2H     2M    24L
  Base image         │  node:25-slim          │    0C     1H     2M    24L
```

One `FROM` change: **2 critical eliminated, 25 high eliminated, image 4x smaller.**
