# Security model

## Local data

Drafts, notes, progress, review history, custom tests, and imported materials
remain in application-support storage. There is no account, telemetry, or
automatic sync. Save operations are serialized; navigation and lifecycle
transitions can await the pending queue, and failures are shown in the UI.

Progress imports reject absolute/traversal paths, links, directories,
duplicates, excessive file counts, oversized compressed archives, oversized
entries, excessive cumulative expanded data, unsupported schema versions,
manifest mismatches, and checksum failures. Import first creates a local backup
and rolls material files back if persistence fails.

## Linux execution

Only scratch Run Code is enabled. The loopback Dart bridge transfers validated
source through JSON/stdin into a Docker container configured with no network,
capabilities, privilege, or host mounts; a non-root user, read-only root, and
CPU/memory/PID/time/output limits are enforced. Structured Tests/Submit are
blocked because their former backend bypassed this boundary.

The unauthenticated loopback port trusts software running as the local user.
The Docker tag is not yet digest-pinned or vulnerability-scanned.

## Android execution

`PythonJudgeService` is non-exported and runs in a separate process. IPC sizes,
concurrency, and output are bounded; the host kills the service process after a
timeout. Embedded CPython still runs with the app UID and is **not a secure
hostile-code sandbox**. Android backup is disabled and the main manifest
requests no runtime permissions.

## Web

Web uses `UnsupportedJudgeService`; it does not silently execute Python.

Security claims must be tied to an executed check. The current verification
results are reported with each reviewed change rather than frozen here.
