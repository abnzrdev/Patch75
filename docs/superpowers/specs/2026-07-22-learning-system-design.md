# Offline Learning System Design

## Decision

Build three independently committable layers on the existing local-first app:

1. FSRS reviews and attempt history.
2. Progressive hints, custom tests, and complexity reflection.
3. Versioned ZIP export/import and operating-system sharing.

The existing versioned `AppState` JSON remains the source of truth. Feature
models serialize into it, while focused repository interfaces and services own
review scheduling, attempt updates, custom-test validation, complexity
normalization, and archive I/O. Widgets receive state and callbacks from the
controller; no filesystem, ZIP, FSRS, or judge logic enters widgets.

## Review model and scheduling

`ReviewRecord` is unique by problem slug and stores the `fsrs` 2.0.1 card map,
immutable event logs with stable IDs, UTC due/review timestamps, state,
stability, difficulty, retrievability, and audit timestamps. A solved problem
without a record is migrated once. `FsrsSchedulerService` wraps the maintained
package with desired retention 0.90, bounded to 0.70–0.99.

`ReviewAttempt` separately records timer and judge telemetry. Starting a review
persists an active attempt so rebuilds, rotation, and process restart retain it.
Lifecycle suspension pauses elapsed-time accrual. Abandoning closes the attempt
without an FSRS event. Completing shows telemetry, complexity answers, and all
four proposed intervals; only an explicit Again/Hard/Good/Easy action schedules
the card.

The queue sorts overdue, due, new, then upcoming. Difficulty targets default to
20/35/50 minutes and remain editable settings. Postpone changes a manual due
override without fabricating an FSRS rating.

## Learning tools and judge boundary

Checked-in problem learning metadata supplies three ordered, original hints and
expected time/space complexity with an explanation for all Blind 75 entries.
Hints reveal sequentially and only update active-attempt telemetry.

`CustomTestCase` uses stable IDs, bounded JSON values, enabled state, ordering,
and timestamps. The same existing `JudgeTestInput` model carries custom inputs
to both desktop and Android services. Custom runs are always `submit: false`,
are displayed separately, and never update solved progress. Official request
and hidden-test behavior remain unchanged.

Complexity comparison normalizes case, whitespace, multiplication symbols,
superscripts, and equivalent parentheses. It reports correct, partial, or
different; it never claims to infer complexity from source code.

## Archive and transaction safety

`ProgressArchiveService` creates a ZIP containing `manifest.json`, versioned
JSON data, and optionally managed material files. Entries use deterministic
relative paths, SHA-256 checksums, declared sizes, UTC export time, app version,
and a persistent random origin-device ID.

Import validates the central directory before mutation: schema, path safety,
entry count, per-file/total limits, duplicate paths, sizes, and checksums. It
then returns a preview. Applying merge or replace first writes a complete local
backup, stages material files, computes the new state, atomically saves it, and
only then swaps staged materials. Any failure restores state and materials.

Merge deduplicates immutable events by stable ID, takes newer mutable records,
merges custom tests by ID, preserves material conflicts under distinct managed
names, and rebuilds FSRS cards by replaying chronological review logs. Replace
uses the validated archive snapshot without deleting the safety backup.

Android uses the system document picker and share sheet. Desktop saves through
the picker and can reveal the destination folder. No account, online service,
automatic download, LocalSend dependency, or LAN synchronization is added.

## UI and accessibility

The existing Olt palette/panels gain a top-level Review destination with a due
badge. Review queue, timed workspace header, summary/rating sheet, history,
hints, custom tests, complexity check, and portability screens keep the dark
lime identity, 44 px controls, semantics, focus states, keyboard traversal,
scrolling, and adaptive desktop/Android layouts.

## Error handling and tests

Invalid records are rejected without replacing local state. Missing/corrupt
archives and unsupported judge inputs produce actionable messages. Tests cover
model migrations, all FSRS ratings, UTC, timers, telemetry, hints, custom judge
separation, complexity normalization, archive validation/merge/rollback, the
responsive widgets, and a full learning/export/import flow. Linux and the
physical Android device are manually smoked; Windows is honestly reported only
after its workflow executes.
