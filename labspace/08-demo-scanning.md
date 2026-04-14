# Demo #6 — BP#5: Scan Continuously, Not Just at Build

> **Best Practice #5:** New CVEs are disclosed every day against images you built
> months ago. Scanning must happen throughout the entire SDLC — at code, build,
> registry push, and in production.

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

The `compare` output shows exactly which packages were added/removed/changed and
which CVEs were introduced or eliminated — actionable signal, not just noise.

## Recommendations — base image upgrade path

```bash terminal-id=build
docker scout recommendations catalog-service:slim --org $$org$$
```

Scout shows the exact upgrade tag that resolves remaining CVEs, along with how many
vulnerabilities each candidate eliminates.

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
the gate that prevents vulnerable images from reaching production.

## Background SBOM indexing in Docker Desktop

Enable via **Settings → General → Enable background Scout SBOM indexing**.

Scout continuously analyses every image you pull or build — you get alerts before
you even think to scan.
