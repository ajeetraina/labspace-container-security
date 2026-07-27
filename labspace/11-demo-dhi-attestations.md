# Demo #9 — DHI Attestations and Scanner Integration

An attestation is a signed statement that provides verifiable information about an image or chart, such as how it was built, what's inside it, and what security checks it has passed. Attestations are typically signed using Sigstore tooling (such as Cosign), making them tamper-evident and cryptographically verifiable.

Docker Hardened Images (DHIs) and charts include comprehensive, signed security attestations that verify the image's build process, contents, and security posture. These attestations are a core part of secure software supply chain practices and help users validate that an image is trustworthy and policy-compliant.

> **Built-in supply chain security:** Every DHI ships with signed SBOMs, VEX documents,
> and SLSA provenance for audit-ready pipelines.

# Why are attestations important?

Attestations provide critical visibility into the software supply chain by:

- Documenting what went into an image (e.g., SBOMs)
- Verifying how it was built (e.g., build provenance)
- Capturing what security scans it has passed or failed (e.g., CVE reports, secrets scans, test results)
- Helping organizations enforce compliance and security policies
- Supporting runtime trust decisions and CI/CD policy gates
- They are essential for meeting industry standards such as SLSA, and help teams reduce the risk of supply chain attacks by making build and security data transparent and verifiable.

# How Docker Hardened Images and charts use attestations

All DHIs and charts are built using SLSA Build Level 3 practices, and each image variant is published with a full set of signed attestations. These attestations allow users to:

- Verify that the image or chart was built from trusted sources in a secure environment
- View SBOMs in multiple formats to understand component-level details
- Review scan results to check for vulnerabilities or embedded secrets
- Confirm the build and deployment history of each image

Attestations are automatically published and associated with each DHI and chart. They can be inspected using tools like Docker Scout or Cosign, and are consumable by CI/CD tooling or security platforms.

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
| in-toto vulnerabilities | Known CVEs affecting the image's components |
| SLSA provenance | Source, build params, and environment details |
| SLSA verification summary | Image's compliance with SLSA requirements |
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
    --format '{{json .Provenance}}' | head -80
```

## Verify the image signature

```bash terminal-id=build
docker trust inspect --pretty $$dhiPrefix$$node:24-debian13
```

## FedRAMP / FIPS compliance

DHI includes FIPS 140-validated cryptographic modules for regulated environments
(government, healthcare, finance, defense).

```bash terminal-id=build
docker scout attest get \
    --predicate-type https://docker.com/dhi/fips/v0.1 \
    --predicate \
    $$dhiPrefix$$node:24-debian13-fips
```

```plaintext no-copy-button
"certification": "CMVP #4985",
"certificationUrl": "https://csrc.nist.gov/projects/cryptographic-module-validation-program/certificate/4985",
"name": "OpenSSL FIPS Provider",
"standard": "FIPS 140-3",
"status": "active",
"sunsetDate": "2030-03-10"
```

## STIG attestation

Security Technical Implementation Guides (STIGs) are configuration standards published by the U.S. Defense Information Systems Agency (DISA). 
They define security requirements for operating systems, applications, databases, and other technologies used in U.S. Department of Defense (DoD) environments.

STIGs help ensure that systems are configured securely and consistently to reduce vulnerabilities. They are often based on broader requirements like the DoD's General Purpose Operating System Security Requirements Guide (GPOS SRG).

## How Docker Hardened Images help apply STIG guidance

Docker Hardened Images (DHIs) include STIG variants that are scanned against custom STIG-based profiles and include signed STIG scan attestations. 
These attestations can support audits and compliance reporting.

While Docker Hardened Images are available to all, the STIG variant requires a Docker subscription.

- Docker creates custom STIG-based profiles for images based on the GPOS SRG and DoD Container Hardening Process Guide.
- Because DISA has not published a STIG specifically for containers, these profiles help apply STIG-like guidance to container environments in a consistent, reviewable way and are designed to reduce false positives common in container images.

```bash terminal-id=build
docker scout attest get \
    --predicate-type https://docker.com/dhi/stig/v0.1 \
    --predicate \
    $$dhiPrefix$$node:24-debian13-fips
```

## VEX export — integration with external scanners

VEX documents tell external scanners (Grype, Trivy, Wiz) which CVEs have already been
assessed as non-exploitable — eliminating false positives automatically.

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
