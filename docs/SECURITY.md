# Security Review

Review date: 2026-07-16. OWASP MASVS was used as guidance for storage,
platform interaction, code execution, network exposure, and release settings.

## Fixed findings

- The desktop bridge binds only to `127.0.0.1`; it has no LAN listener or CORS
  configuration.
- Problem slugs, languages, test IDs, source size, request size, test count,
  array length, output size, and response size are validated.
- User code is passed through stdin and never interpolated into a shell command.
- Docker receives an argument array, has no network/capabilities/privileges/host
  mounts, uses a read-only root, non-root UID, resource limits, and two timeout
  layers.
- State writes are serialized, flushed to a sibling file, and renamed. Corrupt
  JSON is preserved as a timestamped recovery file before defaults load.
- The Android Python service is non-exported, runs in a separate process, limits
  IPC, rejects concurrent work, and has its process killed on timeout.
- Android backup is disabled. The main manifest has no requested permissions,
  exported service, embedded secrets, analytics, or cleartext-network opt-in.
- Unlicensed LeetCodeAnimation media is not copied or packaged.
- Dynamic cojudge test expressions are accepted only by one exact bounded regex;
  arbitrary JavaScript is rejected.

## Verification

- `flutter analyze`: no issues.
- All direct Dart dependencies are current according to `flutter pub outdated`.
- Repository secret-pattern scan found no credentials.
- Android profile APK permissions were `INTERNET` plus Android's generated
  non-exported receiver permission. `INTERNET` comes from Flutter's profile
  tooling; the production main manifest does not request it.
- Passing, wrong-answer, and infinite-loop execution ran on Docker and on the
  physical Android device.
- Docker runtime digest and container arguments were recorded and unit tested.

No Trivy, OSV-Scanner, or Semgrep executable was installed, so no claim is made
that those scanners passed.

## Accepted MVP limitations

- Embedded CPython is not a secure sandbox. The separate Android process shares
  the app UID, restricted builtins can be bypassed by sufficiently hostile
  Python, and process termination is the reliable timeout boundary.
- The localhost bridge has no authentication. Loopback binding and same-user
  trust are the boundary; hostile local software can submit jobs.
- Problem statements originate upstream and are rendered as plain Flutter text,
  not executable HTML. Their factual accuracy is not guaranteed.
- Local notes/drafts are not encrypted because they contain no credentials and
  have no account sync. OS application-data permissions are the boundary.
- Docker image vulnerability scanning was unavailable. The image is digest
  recorded but not cryptographically pinned in configuration.

## Future hardening

- Ship ABI-specific APK/App Bundles and a release-signing configuration.
- Pin Docker by digest and scan it in CI.
- Move Android execution to a dedicated isolated UID if Chaquopy runtime storage
  can be made compatible, or replace CPython with a purpose-built sandbox.
- Add a per-launch random bridge token if local multi-user threat models require
  it.
- Add fuzz/property tests for malformed normalized JSON and IPC payloads.

