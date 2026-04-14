#!/usr/bin/env bash
# =============================================================================
# push-labspace.sh
#
# Pushes all labspace content directly to GitHub via the API.
# No clone needed. Just run it anywhere with curl and your token.
#
# Usage:
#   export GITHUB_TOKEN=ghp_your_token_here
#   bash push-labspace.sh
#
# The script uses the labspace-starter folder structure:
#   labspace/labspace.yaml
#   labspace/01-introduction.md
#   labspace/02-setup.md
#   ... etc
#   compose.override.yaml
# =============================================================================

set -euo pipefail

OWNER="ajeetraina"
REPO="labspace-container-secutiry"
BRANCH="main"
BASE="https://api.github.com/repos/${OWNER}/${REPO}/contents"

BOLD="\033[1m"; GREEN="\033[0;32m"; RED="\033[0;31m"; RESET="\033[0m"

# ── Token check ──────────────────────────────────────────────────────────────
if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo -e "${RED}ERROR:${RESET} Set GITHUB_TOKEN first:"
  echo "  export GITHUB_TOKEN=ghp_your_token_here"
  exit 1
fi

# ── Helper: push one file ─────────────────────────────────────────────────────
push_file() {
  local path="$1"   # path in repo, e.g. labspace/labspace.yaml
  local content="$2" # raw file content

  echo -ne "  ${path} ... "

  # Base64-encode content
  local b64
  b64=$(printf '%s' "$content" | base64 | tr -d '\n')

  # Get current SHA if file exists (needed for updates)
  local sha
  sha=$(curl -sf -H "Authorization: token ${GITHUB_TOKEN}" \
    "${BASE}/${path}" 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('sha',''))" 2>/dev/null || echo "")

  # Build JSON payload
  local payload
  if [ -n "$sha" ]; then
    payload=$(python3 -c "
import json, sys
print(json.dumps({
  'message': 'chore: update ${path}',
  'content': sys.argv[1],
  'branch': '${BRANCH}',
  'sha': sys.argv[2]
}))" "$b64" "$sha")
  else
    payload=$(python3 -c "
import json, sys
print(json.dumps({
  'message': 'feat: add ${path}',
  'content': sys.argv[1],
  'branch': '${BRANCH}'
}))" "$b64")
  fi

  local http_code
  http_code=$(curl -s -o /tmp/gh_response.json -w "%{http_code}" \
    -X PUT \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "${BASE}/${path}")

  if [[ "$http_code" == "200" || "$http_code" == "201" ]]; then
    echo -e "${GREEN}✓${RESET}"
  else
    echo -e "${RED}✗ HTTP $http_code${RESET}"
    cat /tmp/gh_response.json
    exit 1
  fi
}

echo -e "\n${BOLD}Pushing labspace content to ${OWNER}/${REPO}${RESET}\n"

# =============================================================================
# FILE: labspace/labspace.yaml
# =============================================================================
push_file "labspace/labspace.yaml" \
'title: Creating a More Secure Production with Containers
description: |
  A hands-on lab covering all 8 container security best practices using the
  catalog-service-node app — from surfacing CVEs all the way to Docker Hardened Images
  with SBOM, VEX, FIPS, and SLSA provenance attestations.
  Content merges the Docker samples DHI Node labspace with the full security best
  practices narrative from the slide deck.

sections:
  - title: Introduction
    contentPath: 01-introduction.md
  - title: Setup
    contentPath: 02-setup.md
  - title: "Demo #1 - Surface the Problem"
    contentPath: 03-demo-surface-problem.md
  - title: "Demo #2 - BP#1: Minimal Base Images"
    contentPath: 04-demo-minimal-base.md
  - title: "Demo #3 - BP#2: Multi-Stage Builds"
    contentPath: 05-demo-multistage.md
  - title: "Demo #4 - BP#3: Non-Root User"
    contentPath: 06-demo-nonroot.md
  - title: "Demo #5 - BP#4: Read-Only + Drop Capabilities"
    contentPath: 07-demo-readonly-caps.md
  - title: "Demo #6 - BP#5: Continuous Scanning with Scout"
    contentPath: 08-demo-scanning.md
  - title: "Demo #7 - BP#6, #7, #8: Secrets and Limiting Tools"
    contentPath: 09-demo-secrets-tools.md
  - title: "Demo #8 - Migrate to Docker Hardened Images"
    contentPath: 10-demo-dhi-migration.md
  - title: "Demo #9 - DHI Attestations + Scanner Integration"
    contentPath: 11-demo-dhi-attestations.md

services:
  - title: App
    url: http://localhost:3050
    icon: draft
    id: app
'

# =============================================================================
# FILE: labspace/01-introduction.md
# =============================================================================
push_file "labspace/01-introduction.md" \
'# Introduction

👋 Welcome to **Creating a More Secure Production with Containers**!

This lab walks you through **8 container security best practices** and a full
**Docker Hardened Images (DHI) migration** using the catalog-service-node app —
a real-world Node.js service with PostgreSQL, Kafka, and S3 dependencies.

---

## Docker Hardened Images — why they matter

Docker Hardened Images are secure, minimal, production-ready images with near-zero CVEs
and an enterprise-grade SLA for rapid remediation. They follow a **distroless philosophy**,
removing unnecessary components to significantly reduce the attack surface:

- **Near-zero exploitable CVEs** — continuously updated and published with signed
  attestations to eliminate patch fatigue and false positives
- **Seamless migration** — drop-in replacements for popular base images, with `-dev`
  variants for multi-stage builds
- **Up to 95% smaller attack surface** — no shells, no package managers, no OS noise
- **Built-in supply chain security** — signed SBOMs, VEX documents, and SLSA provenance
  for audit-ready pipelines

---

## What you will do in this lab

| Demo | Best Practice |
|------|---------------|
| #1 | Surface the problem — CVE exposure in unverified images |
| #2 | BP#1: Start with minimal base images |
| #3 | BP#2: Use multi-stage builds to keep prod images clean |
| #4 | BP#3: Run as non-root user |
| #5 | BP#4: Read-only filesystem + drop Linux capabilities |
| #6 | BP#5: Scan continuously, not just at build time |
| #7 | BP#6, #7, #8: Secrets management + limit dev/OS tools |
| #8 | Migrate catalog-service-node to DHI |
| #9 | DHI attestations — SBOM, VEX, FIPS, SLSA, scanner integration |

> **Key numbers:**
> - `node:18` → **242 CVEs, 693 packages**
> - `node:25-slim` → **30 CVEs, 272 packages**
> - DHI runtime → **0 critical/high CVEs, ~12 packages**
'

# =============================================================================
# FILE: labspace/02-setup.md
# =============================================================================
push_file "labspace/02-setup.md" \
'# Setup

## 1. Docker org setup

::variableDefinition[org]{prompt="What is your Docker Organization?"}

## 2. DHI tier selection

DHI offers both a **free tier** and a **paid tier**.

- **Free tier** — images at the `dhi.io` registry, no Docker Hub subscription needed
- **Paid tier** — images mirrored into your org on Docker Hub

> **How to choose?** Use the free tier unless you have a paid plan and have the
> `dhi.io/node` image mirrored in your organization.

::variableSetButton[Use the free tier]{variables="tier=free,dhiPrefix=dhi.io/"}

::variableSetButton[Use the paid tier ($$org$$)]{variables="tier=paid,dhiPrefix=$$org$$/dhi-"}

## 3. Docker login

```bash
docker login
```

:::conditionalDisplay{variable="tier" requiredValue="free"}
Also log in to the `dhi.io` registry:

```bash
docker login dhi.io
```
:::

## 4. Configure Docker Scout organization

```bash
docker scout config organization $$org$$
```

## 5. Clone and bootstrap the project

The setup script applies a patch that deliberately introduces a vulnerable state —
old base image and downgraded dependencies — so we can run the full security journey.

```bash terminal-id=main
git clone https://github.com/dockersamples/catalog-service-node
cd catalog-service-node
./demo/sdlc-e2e/setup.sh
```

```bash terminal-id=main
docker rm $(docker ps -a -q) -f
clear
```

```bash terminal-id=npm
cd catalog-service-node
npm install
clear
```

Pre-build the initial image:

```bash terminal-id=build
cd catalog-service-node
docker build -t catalog-service --sbom=true --provenance=mode=max .
clear
```
'

# =============================================================================
# FILE: labspace/03-demo-surface-problem.md
# =============================================================================
push_file "labspace/03-demo-surface-problem.md" \
'# Demo #1 — Surface the Problem

> **The four attack vectors that keep production teams up at night:**
> Image Vulnerabilities · Supply Chain Integrity · Runtime Attack Surface · Compliance

## What are we starting with?

Open the :fileLink[Dockerfile]{path="catalog-service-node/Dockerfile" line=8}.

After the setup patch, the base image is `node:18` — a full, unoptimised image.
Let'"'"'s measure the cost.

## Quick vulnerability overview

```bash terminal-id=build
docker scout quickview catalog-service --org $$org$$
```

Expected output (approximate):

```none no-copy-button
  Target             │  catalog-service:latest  │    2C    26H    25M   122L     4?
    digest           │  360db4f00cbd            │
  Base image         │  node:18                 │    2C    26H    25M   122L     4?
  Updated base image │  node:25-slim            │    0C     1H     2M    24L
                     │                          │    -2    -25    -23    -98     -4
```

Scout is already pointing at the answer: one `FROM` line change eliminates
**2 critical and 25 high** CVEs immediately.

## Policy evaluation

```bash terminal-id=build
docker scout policy catalog-service --org $$org$$
```

```none no-copy-button
Policy status  FAILED  (4/7 policies met)

  Status │                     Policy                     │           Results
─────────┼────────────────────────────────────────────────┼──────────────────────────────
  ✓      │ Default non-root user                          │
  !      │ AGPL v3 licenses found                         │    3 packages
  !      │ Fixable critical or high vulnerabilities found │    2C    26H     0M     0L
  ✓      │ No high-profile vulnerabilities                │
  ✓      │ No outdated base images                        │
  !      │ Unapproved base images found                   │    1 deviation
  ✓      │ Supply chain attestations                      │    0 deviations
```

4/7 policies failing. This is the **reactive "scan and fix"** cycle — developers spend
3 days researching, rebuild, still 189 vulnerabilities remain, cycle repeats.

**Let'"'"'s fix this proactively.**
'

# =============================================================================
# FILE: labspace/04-demo-minimal-base.md
# =============================================================================
push_file "labspace/04-demo-minimal-base.md" \
'# Demo #2 — BP#1: Minimal Base Images

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

```bash terminal-id=build
docker scout quickview catalog-service:slim --org $$org$$
```

```none no-copy-button
  Target             │  catalog-service:slim  │    0C     2H     2M    24L
  Base image         │  node:25-slim          │    0C     1H     2M    24L
```

One `FROM` change: **2 critical eliminated, 25 high eliminated, image 4x smaller.**
'

# =============================================================================
# FILE: labspace/05-demo-multistage.md
# =============================================================================
push_file "labspace/05-demo-multistage.md" \
'# Demo #3 — BP#2: Multi-Stage Builds

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
- `--ignore-scripts` — no post-install scripts (a supply chain attack vector)
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

## Why `--ignore-scripts` matters

```bash terminal-id=build
docker scout cves catalog-service:prod --only-severity critical,high --org $$org$$
```

Post-install scripts are a well-known supply chain attack vector (e.g. the `node-ipc`
incident in 2022). `--ignore-scripts` prevents them from running during `npm ci`.
'

# =============================================================================
# FILE: labspace/06-demo-nonroot.md
# =============================================================================
push_file "labspace/06-demo-nonroot.md" \
'# Demo #4 — BP#3: Non-Root User

> **Best Practice #3:** Never run containers as root.
> Root inside a container is effectively root on the host if isolation fails.

## Three ways to enforce non-root

**Option A — In the Dockerfile (recommended):**

Open :fileLink[Dockerfile]{path="catalog-service-node/Dockerfile" line=12}:

```dockerfile no-copy-button
RUN useradd -m appuser && chown -R appuser /usr/local/app
USER appuser
```

**Option B — At `docker run` time:**

```bash terminal-id=build
docker run --rm --user 1000:1000 catalog-service:slim \
    node -e "console.log(process.getuid())"
```

Expected: `1000` — not `0`.

**Option C — In `docker compose`:**

```yaml no-copy-button
services:
  catalog:
    build: .
    user: "${CURRENT_UID}"
```

## Verify the running user

```bash terminal-id=build
docker run --rm catalog-service:slim whoami
```

Expected: `appuser` — not `root`.

## The hardened `docker init` pattern

```dockerfile no-copy-button
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    appuser
USER appuser
```

No home dir, no login shell, no password — minimal footprint.

## Confirm Scout policy

```bash terminal-id=build
docker scout quickview catalog-service:slim --org $$org$$
```

Look for `Default non-root user` — should show ✓.
'

# =============================================================================
# FILE: labspace/07-demo-readonly-caps.md
# =============================================================================
push_file "labspace/07-demo-readonly-caps.md" \
'# Demo #5 — BP#4: Read-Only Filesystem + Drop Linux Capabilities

> **Best Practice #4:** Even if an attacker gains code execution, a read-only container
> with dropped capabilities severely limits what they can do next.

## Linux capabilities — what gets dropped with `--cap-drop=ALL`

| Capability | What it allows |
|------------|----------------|
| `CHOWN` | Change file UIDs/GIDs |
| `DAC_OVERRIDE` | Bypass file permission checks |
| `NET_RAW` | Raw/packet sockets (network attacks) |
| `SETUID` / `SETGID` | Change process UID/GID |
| `SYS_CHROOT` | `chroot()` — change root directory |
| `KILL` | Send signals to other processes |
| `MKNOD` | Create special files |

## Run with hardened flags

```bash terminal-id=build
docker run \
    -d \
    -p 3000:3000 \
    --read-only \
    --cap-drop=ALL \
    --user=65532 \
    --name catalog-hardened \
    catalog-service:slim
```

```bash terminal-id=build
curl http://localhost:3000
```

## Verify the filesystem is read-only

```bash terminal-id=build
docker exec catalog-hardened sh -c "echo test > /tmp/test.txt"
```

Expected: `Read-only file system` — the attacker cannot write anywhere.

## When your app needs a writable area — use `tmpfs`

```bash terminal-id=build
docker run \
    -d \
    -p 3001:3000 \
    --read-only \
    --tmpfs /tmp \
    --cap-drop=ALL \
    --user=65532 \
    --name catalog-hardened-tmpfs \
    catalog-service:slim
```

```bash terminal-id=build
docker exec catalog-hardened-tmpfs sh -c "echo test > /tmp/test.txt && cat /tmp/test.txt"
```

`/tmp` is in-memory and writable; everything else stays read-only.

## Clean up

```bash terminal-id=build
docker rm -f catalog-hardened catalog-hardened-tmpfs
```
'

# =============================================================================
# FILE: labspace/08-demo-scanning.md
# =============================================================================
push_file "labspace/08-demo-scanning.md" \
'# Demo #6 — BP#5: Scan Continuously, Not Just at Build

> **Best Practice #5:** New CVEs are disclosed every day against images you built
> months ago. Scanning must happen throughout the entire SDLC.

## The three Scout commands

**Quickview — fast summary:**

```bash terminal-id=build
docker scout quickview catalog-service:slim --org $$org$$
```

**CVE drill-down — critical and high only:**

```bash terminal-id=build
docker scout cves catalog-service:slim \
    --only-severity critical,high \
    --org $$org$$
```

**Compare — see exactly what changed between two images:**

```bash terminal-id=build
docker scout compare \
    --ignore-unchanged \
    --to catalog-service \
    catalog-service:slim \
    --org $$org$$
```

## Recommendations — base image upgrade path

```bash terminal-id=build
docker scout recommendations catalog-service:slim --org $$org$$
```

Scout shows the exact upgrade tag that resolves remaining CVEs.

## Integrate Scout into CI

Open :fileLink[.github/workflows/pipeline-docker-cloud.yaml]{path="catalog-service-node/.github/workflows/pipeline-docker-cloud.yaml"}.

Key gate step:

```yaml no-copy-button
      - name: Docker Scout CVEs
        uses: docker/scout-action@v1
        with:
          command: cves
          image: ${{ steps.build.outputs.imageid }}
          only-severities: critical,high
          exit-code: true
```

`exit-code: true` makes the pipeline **fail** if critical/high CVEs are found —
the gate that prevents vulnerable images reaching production.

## Background SBOM indexing in Docker Desktop

Enable via **Settings → General → Enable background Scout SBOM indexing**.
Scout analyses every image you pull or build automatically.
'

# =============================================================================
# FILE: labspace/09-demo-secrets-tools.md
# =============================================================================
push_file "labspace/09-demo-secrets-tools.md" \
'# Demo #7 — BP#6, #7, #8: Secrets, Dev Tools, OS Tools

> **Best Practices #6, #7, #8:** Secrets must never be baked in.
> Production images must exclude dev and OS tools.

## BP#6 — Secrets and containers

| Location | Risk |
|----------|------|
| In source code | Visible to anyone with repo access |
| Built into the image | Visible via `docker history` |
| In execution scripts committed to SCM | Same as source code |
| In an environment variable | Shows in log dumps, visible to all processes |
| In a file on disk | Available to any process on the machine |
| **In a secrets vault** | **Only available to the process asking for it ✓** |

### Inspect image layers — confirm no secrets leaked

```bash terminal-id=build
docker history catalog-service:slim
```

### BuildKit build-time secrets (never written to any layer)

```dockerfile no-copy-button
# WRONG — SSH key baked into layer forever
RUN cp /root/.ssh/id_rsa /app/key

# RIGHT — BuildKit secret, never written to any layer
RUN --mount=type=secret,id=mysecret cat /run/secrets/mysecret
```

```bash no-copy-button
docker build --secret id=mysecret,src=./mysecret.txt -t myapp .
```

## BP#7 — No dev tools in production

```bash terminal-id=build
docker run --rm catalog-service:slim which npm   || echo "npm not found — good"
```

```bash terminal-id=build
docker run --rm catalog-service:slim which yarn  || echo "yarn not found — good"
```

```bash terminal-id=build
docker run --rm catalog-service:slim which git   || echo "git not found — good"
```

## BP#8 — No OS tools in production

```bash terminal-id=build
docker run --rm catalog-service:slim which curl    || echo "curl not found — good"
```

```bash terminal-id=build
docker run --rm catalog-service:slim which wget    || echo "wget not found — good"
```

```bash terminal-id=build
docker run --rm catalog-service:slim which apt-get || echo "apt-get not found — good"
```

```bash terminal-id=build
docker run --rm catalog-service:slim which sudo    || echo "sudo not found — good"
```

> **Why no curl?** An attacker with code execution uses `curl` to download additional
> payloads. Removing it meaningfully raises the cost of a successful exploit.

## Attack surface count so far

```bash terminal-id=build
docker scout cves catalog-service:slim --format only-packages --org $$org$$
```

Started at **693 packages** (`node:18`). Now at **~272** (`node:25-slim`).
Demo #8 takes it to **~12**.
'

# =============================================================================
# FILE: labspace/10-demo-dhi-migration.md
# =============================================================================
push_file "labspace/10-demo-dhi-migration.md" \
'# Demo #8 — Migrate to Docker Hardened Images

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

- **595 packages removed** — 595 fewer CVE vectors
- **179 vulnerabilities removed** across all severities
- Image is **10x smaller**

## The no-shell demo

```bash terminal-id=build
docker run --rm catalog-service:dhi sh
```

Expected: error — `sh` does not exist. Compare to slim:

```bash terminal-id=build
docker run --rm catalog-service:slim sh -c "echo shell available"
```

## DHI vs slim — property comparison

| Property | `node:25-slim` | DHI runtime |
|----------|---------------|-------------|
| CVEs (critical/high) | 2H | 0C 0H |
| Package count | ~272 | ~12 |
| Shell in runtime | Yes | No (distroless) |
| Non-root by default | Manual | Built-in |
| SBOM | Build-time only | Cryptographically signed |
| VEX document | No | Yes |
| SLSA provenance | Build-time only | Verified |
| FIPS variant | No | Yes |
| STIG variant | No | Yes |
| 7-day CVE SLA | No | Yes |
'

# =============================================================================
# FILE: labspace/11-demo-dhi-attestations.md
# =============================================================================
push_file "labspace/11-demo-dhi-attestations.md" \
'# Demo #9 — DHI Attestations and Scanner Integration

> **Built-in supply chain security:** Every DHI ships with signed SBOMs, VEX documents,
> and SLSA provenance for audit-ready pipelines.

## List all attestations

```bash terminal-id=build
docker scout attest list $$dhiPrefix$$node:24-debian13
```

| Attestation | What it is |
|-------------|------------|
| CycloneDX SBOM | Bill of materials — components, libraries, versions |
| SPDX SBOM | SBOM in SPDX format (widely adopted in open-source) |
| Scout SBOM | SBOM generated and signed by Docker Scout |
| OpenVEX | Identifies non-applicable CVEs and explains why |
| in-toto vulnerabilities | Known CVEs affecting the image components |
| SLSA provenance | Source, build params, and environment details |
| SLSA verification summary | Image compliance with SLSA requirements |
| Scout health | Signed summary of security and quality posture |
| Scout secret scan | Results of a secrets scan |
| Scout test report | Record of automated tests run against the image |

## View the SPDX SBOM

```bash terminal-id=build
docker scout attest get $$dhiPrefix$$node:24-debian13 \
    --predicate-type https://spdx.dev/Document
```

## Inspect the SLSA provenance

```bash terminal-id=build
docker buildx imagetools inspect $$dhiPrefix$$node:24-debian13 \
    --format '"'"'{{json .Provenance}}'"'"' | head -80
```

## Verify the image signature

```bash terminal-id=build
docker trust inspect --pretty $$dhiPrefix$$node:24-debian13
```

## FedRAMP / FIPS compliance

```bash terminal-id=build
docker scout attest get \
    --predicate-type https://docker.com/dhi/fips/v0.1 \
    --predicate \
    $$dhiPrefix$$node:24-debian13-fips
```

```plaintext no-copy-button
"certification": "CMVP #4985",
"name": "OpenSSL FIPS Provider",
"standard": "FIPS 140-3",
"status": "active"
```

## STIG attestation

```bash terminal-id=build
docker scout attest get \
    --predicate-type https://docker.com/dhi/stig/v0.1 \
    --predicate \
    $$dhiPrefix$$node:24-debian13-fips
```

## VEX export — integration with external scanners

VEX documents tell external scanners (Grype, Trivy, Wiz) which CVEs have been assessed
as non-exploitable — eliminating false positives automatically.

View attestations on your migrated app image:

```bash terminal-id=build
docker scout attest list catalog-service:dhi
```

Export the merged VEX document:

```bash terminal-id=build
docker scout vex get catalog-service:dhi --output vex.json
```

Pass to Grype:

```bash no-copy-button
grype catalog-service:dhi --vex vex.json
```

Pass to Trivy:

```bash no-copy-button
trivy image --vex vex.json catalog-service:dhi
```

## Key takeaway

> Securing your containers is step one.
> Securing your **supply chain** is the rest.
>
> 1. Know what software you are running — SBOMs, dependency trees, base image provenance
> 2. Know what risks that software has — continuous vulnerability scanning
> 3. Fix those risks quickly — DHI gives you a **7-day SLA** on critical/high CVEs

[Get started with DHI →](https://docs.docker.com/dhi/get-started/)
'

# =============================================================================
# FILE: compose.override.yaml
# =============================================================================
push_file "compose.override.yaml" \
'services:
  configurator:
    environment:
      PROJECT_CLONE_URL: https://github.com/dockersamples/catalog-service-node

  # workspace:
  #   image: dockersamples/labspace-workspace-node
  #   ports: !override
  #     - "3000:3000"   # catalog-service backend
  #     - "3050:3050"   # demo-node app
  #     - "5173:5173"   # demo client
  #     - "5050:5050"   # pgAdmin
  #     - "8080:8080"   # Kafbat UI
'

# =============================================================================
echo ""
echo -e "${BOLD}${GREEN}All files pushed successfully!${RESET}"
echo ""
echo "View your repo: https://github.com/${OWNER}/${REPO}"
echo ""
echo "Start local dev preview:"
echo "  git clone https://github.com/${OWNER}/${REPO}"
echo "  cd ${REPO}"
echo "  CONTENT_PATH=\$PWD docker compose up --watch"
echo "  open http://localhost:3030"
