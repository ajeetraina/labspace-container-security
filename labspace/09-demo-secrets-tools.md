# Demo #7 — BP#6, #7, #8: Secrets, Dev Tools, OS Tools

> **Best Practices #6, #7, #8:** Secrets must never be baked in.
> Production images must exclude dev and OS tools.

## BP#6 — Secrets and containers

Containers often need credentials: DB passwords, TLS certs, API keys, SSH keys.

The **wrong** approaches — all visible to attackers:

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

Look through every layer — no credentials, tokens, or keys should be visible.

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

Verify the production image has no dev tooling beyond the runtime:

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
