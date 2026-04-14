# Demo #1 — Surface the Problem

> **The four attack vectors that keep production teams up at night:**
> Image Vulnerabilities · Supply Chain Integrity · Runtime Attack Surface · Compliance

## What are we starting with?

Open the :fileLink[Dockerfile]{path="catalog-service-node/Dockerfile" line=8}.

After the setup patch, the base image is `node:18` — a full, unoptimised image.
Let's measure the cost.

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
3 days researching fixes, rebuild, still 189 vulnerabilities remain, cycle repeats,
security blocks deployment.

**Let's fix this proactively, one best practice at a time.**
