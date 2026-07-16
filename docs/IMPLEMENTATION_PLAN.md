# Offline LeetCode Trainer Implementation Plan

> Implementation proceeds test-first in independently runnable phases. Every
> Flutter command starts with `source scripts/flutter-env.sh`.

## Global constraints

- Flutter 3.44.6 and Dart 3.12.2.
- Linux and Android are runtime targets; web must build but browser testing is
  not blocked on missing Chrome.
- No Anki, FSRS, account, cloud sync, analytics, or remote execution.
- External repositories stay under ignored `.cache/external/`.
- LeetCodeAnimation media is never committed without a redistribution license.
- Each verified phase receives a small local commit; nothing is pushed.

## Phase A — normalized data and storage

1. Add model/parser tests for problem JSON, slug normalization, animation
   matching, judge validation, output truncation, state migration, and corrupt
   state fallback.
2. Add `scripts/import_cojudge.dart` to read the pinned cojudge checkout,
   normalize its Blind 75 course and problem directories, preserve attribution,
   and deterministically write app assets.
3. Import Two Sum first, validate its complete statement, examples, constraints,
   Python starter, three sample tests, and official submission tests.
4. Implement the versioned atomic JSON state store plus draft, notes, progress,
   timer, and settings repositories.
5. Verify focused tests, formatting, and analysis; commit data/storage.

## Phase B — Two Sum vertical slice

1. Add micrographic design tokens and shared panel/status/button primitives.
2. Add the app controller and adaptive shell with desktop three-pane and compact
   five-destination layouts.
3. Add the Two Sum statement, examples, constraints, editable `re_editor`
   Python editor, results, notes, timer, focus mode, progress, and explicit
   platform availability.
4. Add draft/notes/timer/focus restoration widget tests, large text and narrow
   viewport tests, and missing/corrupt animation states.
5. Run the app on Linux and the attached Android device for real interaction
   checks; verify tests/analyzer/builds; commit the vertical slice.

## Phase C — animation import and viewer

1. Add `scripts/import_animations.dart` to read the pinned manifest and match
   ID, slug, then title.
2. Generate `assets/data/animation_index.json` with attribution and expected
   local paths. Keep media paths unavailable unless users run the local import
   against their ignored checkout.
3. Add preview, show/hide, fit/zoom, expanded view, loading, missing, and corrupt
   states. Raw source notes remain hidden behind an explicit disclosure.
4. Verify matching unit tests and viewer widget tests; commit.

## Phase D — desktop judge

1. Implement request/result models, allowlist and size validation, bounded
   output, and `UnsupportedJudgeService`.
2. Build a standard-library Dart localhost bridge under `tool/desktop_judge/`
   and `DesktopCojudgeJudgeService`. Reuse cojudge problem contracts and Docker
   images without copying its UI.
3. Enforce localhost binding, JSON/body/source limits, argument arrays,
   temporary-directory permissions, traversal checks, timeouts, output limits,
   unprivileged/no-network/no-capability containers, and cleanup.
4. Test passing/failing Two Sum, infinite loop, oversized source/output, Docker
   unavailable, and bridge restart. Commit only after Linux tests pass.

## Phase E — Android Python

1. Add Chaquopy 17.0 with Python 3.11, minimum SDK 24, Android ABI support, and no
   extra Android permissions.
2. Add a non-exported isolated service and MethodChannel implementation that
   validates requests again, executes the Two Sum harness, bounds output, and
   returns structured results.
3. Kill/recreate the service after timeout and document that Chaquopy is not a
   hostile-code sandbox.
4. Run passing, failing, timeout, oversized, and unsupported-import checks on
   the authorized physical device. Commit only with actual device evidence.

## Phase F — Blind 75 browser

1. Run the deterministic importer for all cojudge Blind 75 records.
2. Add category grouping, search, difficulty and progress filters, compact rows,
   progress summary, and previous/next navigation.
3. Measure decode/load and rapid switching; keep parsing synchronous unless
   measurements justify an isolate.
4. Verify browser/filter/parser tests and all platform builds; commit.

## Phase G — release verification and reports

1. Add critical-flow integration tests and screenshot/golden harnesses for
   desktop, focus, expanded animation, compact destinations, and error states.
2. Run cold/warm startup, 75-record load, 100 judge runs, lifecycle, corrupt
   data, long notes, narrow width, and repeated animation checks.
3. Audit OWASP MASVS-relevant command, path, payload, Docker, Android manifest,
   storage, secret, dependency, symlink, and malformed-input risks.
4. Write `docs/PERFORMANCE.md`, `docs/SECURITY.md`,
   `docs/ANDROID_SETUP.md`, `docs/DESKTOP_JUDGE.md`, and the final README.
5. Run `dart format --set-exit-if-changed .`, `flutter analyze`,
   `flutter test`, `flutter build linux`, `flutter build apk --debug`, and
   `flutter build web`. Record exact outputs and never infer device coverage.
