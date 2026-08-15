# Linux Docker judge

```bash
docker pull python:3.13-alpine
scripts/start-desktop-judge.sh
```

The Dart bridge binds only to `127.0.0.1:5376`, accepts bounded JSON, and
supports Python scratch execution only. Structured Tests/Submit receive an
unavailable result before any HTTP request; the bridge independently rejects
non-scratch modes.

Each scratch run transfers source on stdin and invokes Docker with an argument
array, never a host shell. The container has:

- `--network none`, `--cap-drop ALL`, and `no-new-privileges`
- no privileged mode and no host mounts
- a read-only root and 16 MiB `noexec,nosuid` temporary filesystem
- UID/GID 65534, 128 MiB memory, 64 PIDs, and 0.5 CPU
- a three-second container timeout, ten-second bridge timeout, and 256 KiB I/O limits

The image is currently `python:3.13-alpine`. Pinning it by digest and scanning
that digest remain release-hardening work.
