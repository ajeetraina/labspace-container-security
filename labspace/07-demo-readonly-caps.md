# Demo #5 — BP#4: Read-Only Filesystem + Drop Linux Capabilities

> **Best Practice #4:** Even if an attacker gains code execution, a read-only container
> with dropped capabilities severely limits what they can do next.

## Linux capabilities — what gets dropped with `--cap-drop=ALL`

| Capability | What it allows |
|------------|----------------|
| `CHOWN` | Change file UIDs/GIDs |
| `DAC_OVERRIDE` | Bypass file read/write/execute permission checks |
| `NET_RAW` | Raw and packet sockets (used in some network attacks) |
| `SETUID` / `SETGID` | Change process UID/GID |
| `SYS_CHROOT` | `chroot()` — change root directory |
| `KILL` | Send signals to other processes |
| `MKNOD` | Create special files |

## Step 1 — Clean up any leftover containers from earlier demos

Run this first every time. It removes any containers from a previous attempt so
names and ports are free.

```bash terminal-id=build
docker rm -f catalog-hardened catalog-hardened-tmpfs 2>/dev/null; echo "clean"
```

## Step 2 — Run with hardened flags

```bash terminal-id=build
docker run \
    -d \
    -p 3100:3000 \
    --read-only \
    --cap-drop=ALL \
    --user=65532 \
    --name catalog-hardened \
    catalog-service:slim
```

```bash terminal-id=build
docker ps --filter name=catalog-hardened
```

```bash terminal-id=build
curl http://localhost:3100
```

## Step 3 — Verify the filesystem is read-only

```bash terminal-id=build
docker exec catalog-hardened sh -c "echo test > /tmp/test.txt"
```

Expected: `sh: /tmp/test.txt: Read-only file system`

The attacker gained code execution but **cannot write anywhere** — no dropping
payloads, no modifying config files, no creating SUID binaries.

## Step 4 — Prove the capability drop

```bash terminal-id=build
docker inspect catalog-hardened \
    --format 'ReadonlyRootfs={{.HostConfig.ReadonlyRootfs}} CapDrop={{.HostConfig.CapDrop}}'
```

Expected output:
```none no-copy-button
ReadonlyRootfs=true CapDrop=[ALL]
```

## Step 5 — When your app needs a writable area: use `tmpfs`

`tmpfs` is in-memory only — writable but never persisted to disk, gone when the
container stops:

```bash terminal-id=build
docker run \
    -d \
    -p 3101:3000 \
    --read-only \
    --tmpfs /tmp:noexec,nosuid,size=64m \
    --cap-drop=ALL \
    --user=65532 \
    --name catalog-hardened-tmpfs \
    catalog-service:slim
```

```bash terminal-id=build
docker exec catalog-hardened-tmpfs sh -c "echo test > /tmp/test.txt && cat /tmp/test.txt"
```

`/tmp` is writable in memory. Everything else is still read-only.

Note the extra `tmpfs` flags:
- `noexec` — files in `/tmp` cannot be executed
- `nosuid` — SUID bits on files in `/tmp` are ignored
- `size=64m` — caps memory usage to 64 MB

## Step 6 — Clean up

```bash terminal-id=build
docker rm -f catalog-hardened catalog-hardened-tmpfs
```
