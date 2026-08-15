<h1 align="center">Patch75</h1>

<p align="center">An offline-first 75-problem algorithm practice workspace for Linux and Android.</p>

Patch75 keeps problem browsing, Python drafts, notes, local materials, progress,
and FSRS review history on the device. It has no account, telemetry, analytics,
advertising, or cloud sync.

## What works

- 75 original Patch75 exercises with prompts, examples, constraints, starter code, and deterministic tests
- responsive Problem → Code → Results → Materials/Notes workspace
- per-problem drafts, notes, timers, hints, complexity checks, and local materials
- local review scheduling and validated ZIP progress export/import
- Linux Run Code through a loopback-only, locked-down Docker bridge
- Android Run Code in a non-exported separate Python service process

Linux structured Run Tests and Submit are intentionally disabled until they can
use the same hardened Docker boundary. Web builds support studying and editing
only; they never execute Python.

## Security boundaries

- Linux code is transferred as bounded JSON/stdin and runs in Docker with no
  network, capabilities, privilege, or host mounts; it uses a non-root user, a
  read-only root, and CPU/memory/PID/time/output limits.
- Android's embedded CPython process has timeout and process-kill boundaries,
  but it is **not a secure sandbox for hostile Python**.
- Progress imports validate archive paths, links, counts, compressed and
  cumulative expanded sizes, schema version, manifest membership, and SHA-256
  checksums before replacing local state.

See [SECURITY.md](docs/SECURITY.md) and
[DESKTOP_JUDGE.md](docs/DESKTOP_JUDGE.md).

## Build and test

Requirements: Flutter 3.44.x/Dart 3.12.x, the Linux desktop toolchain, Java 17,
and an Android SDK. Docker is optional and is used only for Linux Run Code.

```bash
source scripts/flutter-env.sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter analyze
flutter test
flutter build linux --release
flutter build apk --release
```

Start the Linux app and optional judge with `scripts/start-linux.sh`, or run the
bridge alone with `scripts/start-desktop-judge.sh`.

Public Android releases must be signed with a maintainer-controlled release key
that is never committed. This repository does not configure debug signing for
release builds; see [ANDROID_SETUP.md](docs/ANDROID_SETUP.md).

## License and content provenance

Patch75-owned source code is licensed under the
[GNU Affero General Public License v3.0 only](LICENSE) (`AGPL-3.0-only`). This
license does not cover third-party names, data, media, or other material that
Patch75 does not own.

The bundled exercises and learning metadata were authored for Patch75 and carry
the same `AGPL-3.0-only` license. Stable IDs and short concept identifiers were
retained to preserve local progress; no prior third-party statements, examples,
constraints, starter code, tests, or screenshots are distributed. Dependency
and historical-content boundaries are recorded in
[LICENSING_REVIEW.md](docs/LICENSING_REVIEW.md) and
[THIRD_PARTY.md](docs/THIRD_PARTY.md).

Architecture, archive format, Android setup, and third-party provenance are
documented under [`docs/`](docs/).
