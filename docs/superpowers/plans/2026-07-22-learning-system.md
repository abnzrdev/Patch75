# Offline Learning System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add FSRS reviews, attempt history, structured learning tools, and safe offline progress portability without changing existing judge semantics.

**Architecture:** Extend the versioned atomic `AppState` document with focused feature models. Repository interfaces and services own scheduling, validation, and archive work; `AppController` coordinates them and adaptive widgets render state.

**Tech Stack:** Flutter/Dart, `fsrs` 2.0.1, `archive`, `crypto`, existing file picker, and platform sharing.

## Global Constraints

- Preserve OltColors/OltPanel, drafts, notes, progress, timers, materials, navigation, and both judge paths.
- UTC in storage; local time only for display.
- Default desired retention 0.90, safely limited to 0.70–0.99.
- Custom tests never count as official submission success.
- No study plan, online downloads, accounts, cloud service, or LAN sync implementation.
- Three fully passing focused commits; never push.

---

### Task 1: FSRS domain and persistence

**Files:** `pubspec.yaml`, `lib/features/review/review_models.dart`, `lib/features/review/fsrs_scheduler_service.dart`, `lib/features/review/review_repository.dart`, `lib/core/storage/app_state.dart`, corresponding tests.

- [ ] Add failing tests for UTC serialization, stable event IDs, all four ratings, due persistence, solved migration, and duplicate prevention.
- [ ] Add `fsrs: ^2.0.1` and implement the minimum package wrapper and serializable records.
- [ ] Extend AppState schema and migration without changing existing fields.
- [ ] Run focused tests and the full suite.

### Task 2: Timed review attempts and queue UI

**Files:** `lib/features/review/review_attempt.dart`, `review_attempt_repository.dart`, `review_timer.dart`, `review_queue_screen.dart`, `review_history_screen.dart`, `review_summary_sheet.dart`, `lib/app/app_controller.dart`, `lib/app/offline_trainer_app.dart`, tests.

- [ ] Add failing timer, abandonment, telemetry, queue sorting, badge, rating, history, and responsive widget tests.
- [ ] Persist active attempts and configurable 20/35/50-minute targets.
- [ ] Create review cards after successful Submit and migrate existing solved progress.
- [ ] Implement queue/start/early/postpone/abandon/rate/history flows.
- [ ] Run format, analyze, full tests, Linux build; commit `feat(review): add FSRS timed review system`.

### Task 3: Learning metadata, hints, and complexity

**Files:** `assets/data/learning_metadata.json`, `lib/features/problems/problem.dart`, `problem_repository.dart`, `lib/features/learning/hint_panel.dart`, `complexity_checker.dart`, tests and asset validation.

- [ ] Add failing coverage requiring exactly three ordered hints and expected complexity for every Blind 75 slug.
- [ ] Check in concise original metadata for all 75 problems and load it with the repository.
- [ ] Implement ordered reveal telemetry and complexity normalization/comparison UI.
- [ ] Run focused and full tests.

### Task 4: Custom tests and shared judge integration

**Files:** `lib/features/custom_tests/custom_test_case.dart`, `custom_test_repository.dart`, `custom_test_editor.dart`, `lib/app/app_controller.dart`, judge contract tests.

- [ ] Add failing validation/persistence/edit/duplicate/delete/reorder/official-separation tests.
- [ ] Implement bounded structured and advanced-JSON custom tests with stable IDs.
- [ ] Run one/all enabled cases through existing shared JudgeTestInput on Linux/Android using `submit: false`.
- [ ] Keep custom results visually separate and update active-attempt telemetry only.
- [ ] Run format, analyze, full tests, both judge contract suites; commit `feat(learning): add hints custom tests and complexity checks`.

### Task 5: Versioned archive service

**Files:** `lib/features/portability/archive_models.dart`, `progress_archive_service.dart`, tests.

- [ ] Add failing deterministic-manifest, checksum, path, size, corrupt ZIP, duplicate-log, conflict, replace, rollback, and reconstruction tests.
- [ ] Add `archive` and `crypto`; create validated progress-only and progress-with-materials ZIPs.
- [ ] Implement inspect/preview and transactional merge/replace with backup and rollback.
- [ ] Run focused and full tests.

### Task 6: Export/import/share UI and documentation

**Files:** `lib/features/portability/portability_screen.dart`, `import_preview_dialog.dart`, platform adapter, `README.md`, `docs/ARCHITECTURE.md`, `docs/FSRS_REVIEW.md`, `docs/EXPORT_FORMAT.md`, `docs/LOCAL_SYNC_FUTURE.md`, `docs/THIRD_PARTY.md`, `.gitignore`, tests.

- [ ] Add failing export-option/import-preview/Android-layout widget and integration-flow tests.
- [ ] Implement document-picker export/import and share/reveal actions with actionable fallbacks.
- [ ] Document FSRS licensing/data, archive schema/merge/rollback, LocalSend workflow, future encrypted LAN sync, Windows CI, and limitations.
- [ ] Run format, analyze, full tests, Linux/APK builds; commit `feat(portability): add progress export import and sharing`.

### Task 7: Platform verification and completion audit

- [ ] Run exact Linux validation and manually smoke all required flows.
- [ ] Build/install/run on `R9ZX30B0CHB`; test both orientations, lifecycle/process persistence, judge, document picker/share/import, and capture logcat.
- [ ] Confirm Windows workflow contains every required command; report it pending unless it actually runs successfully.
- [ ] Audit every supplied requirement against code, tests, runtime evidence, and the three commits.
