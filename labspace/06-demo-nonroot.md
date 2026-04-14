# Demo #4 — BP#3: Non-Root User

> **Best Practice #3:** Never run containers as root.
> Root inside a container is effectively root on the host if isolation fails.

## Why this matters

By default, Docker containers run as `root` (UID 0). If an attacker exploits your app,
they get root-level access inside the container — and potentially on the host if
the container is misconfigured or running with a privileged socket.

## Three ways to enforce non-root

**Option A — In the Dockerfile (recommended, what we already have):**

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

When you run `docker init` in a new project, Docker scaffolds this automatically:

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

Extra hardening: no home dir, no login shell, no password — minimal footprint.

## Confirm Scout policy

```bash terminal-id=build
docker scout quickview catalog-service:slim --org $$org$$
```

Look for `Default non-root user` — should show ✓.
