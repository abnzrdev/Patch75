# Desktop Docker Judge

## Start

```bash
source scripts/flutter-env.sh
docker pull python:3.13-alpine
scripts/start-desktop-judge.sh
```

The bridge binds only to `127.0.0.1:5376`. The Flutter app probes
`GET /health` and posts bounded JSON to `POST /judge`.

## Request

```json
{
  "problemSlug": "two-sum",
  "language": "python",
  "sourceCode": "class Solution: ...",
  "selectedTests": ["sample-1"],
  "tests": [{"id": "sample-1", "nums": [2, 7], "target": 9}]
}
```

## Isolation

The bridge uses a Docker argument array. User code is sent on container stdin
and never appears in a shell command or Docker argument. Each run uses:

- `--network none`
- `--cap-drop ALL`
- `--security-opt no-new-privileges`
- read-only root filesystem and a 16 MiB no-exec temporary filesystem
- 128 MiB memory/memory-swap, 64 PIDs, 0.5 CPU
- UID/GID 65534
- no privileged mode and no host mounts
- three-second in-container timeout and six-second host watchdog
- 256 KiB bridge body and output limits

The pinned runtime observed during verification was
`python@sha256:399babc8b49529dabfd9c922f2b5eea81d611e4512e3ed250d75bd2e7683f4b0`.
The image tag remains configurable only by editing reviewed source.

If Docker, the image, or the bridge is unavailable, Run/Submit is disabled and
all study features remain usable.

