# Introduction

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

> **Key numbers from the slide deck:**
> - `node:18` → **242 CVEs, 693 packages**
> - `node:25-slim` → **30 CVEs, 272 packages**
> - DHI runtime → **0 critical/high CVEs, ~12 packages**
