# Demo #9 — DHI Attestations and Scanner Integration

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
