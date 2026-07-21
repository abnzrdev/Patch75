# Workspace Learning Materials Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve workspace readability and editing while adding safe private per-problem learning-material attachments without changing judge behavior.

**Architecture:** Keep the current controller/state/view structure. Add a serializable attachment value object and one private-file store, preserve legacy animation paths, and build focused reusable workspace widgets around the existing OLT design system and `re_editor`.

**Tech Stack:** Flutter/Dart, `re_editor`, `file_picker`, `path_provider`, `flutter_markdown_plus`, `open_filex`, Flutter test, GitHub Actions.

## Global Constraints

- Preserve existing judge and Cojudge execution paths unchanged.
- Preserve existing drafts, notes, animation paths, problem navigation, Run Tests, and Submit behavior.
- Keep private files under platform application-support storage; never download external media.
- Accept GIF, WebP, PNG, JPEG, PDF, Markdown, TXT, MP4, and WebM; image/document limit 64 MiB, video limit 256 MiB.
- Use at least 44 logical pixel touch targets and retain the dark terminal plus lime identity.
- Back up each tracked file before editing; preserve unrelated untracked files; do not edit generated Flutter files or commit until validation passes.

---

### Task 1: Serializable material state and migration

**Files:**
- Create: `lib/features/materials/learning_material.dart`
- Modify: `lib/core/storage/app_state.dart`
- Test: `test/features/materials/learning_material_test.dart`
- Test: `test/core/storage/app_state_test.dart`

**Interfaces:**
- Produces: `enum LearningMaterialKind { image, markdown, text, pdf, video }`
- Produces: `LearningMaterial.fromJson`, `toJson`, `copyWith`, `isImage`, `friendlyType`
- Produces: `AppState.materials: Map<String, List<LearningMaterial>>`

- [ ] Write failing tests covering JSON round-trip, missing `materials`, per-problem isolation, and legacy `animationPaths` preservation.
- [ ] Run `flutter test test/features/materials/learning_material_test.dart test/core/storage/app_state_test.dart` and confirm failures are caused by absent material types/state.
- [ ] Add the immutable value object, bump `currentSchemaVersion`, deserialize absent fields to empty lists, and include materials in `copyWith`, equality, hash, and JSON.
- [ ] Re-run the focused tests and keep them green.

### Task 2: Safe private material store

**Files:**
- Create: `lib/features/materials/local_material_store.dart`
- Test: `test/features/materials/local_material_store_test.dart`

**Interfaces:**
- Produces: `Future<LearningMaterial?> importForProblem(String slug, {Set<LearningMaterialKind>? kinds, LearningMaterial? replacing})`
- Produces: `Future<void> delete(LearningMaterial material, String slug)`
- Produces: public allowlists and byte limits for deterministic tests.

- [ ] Write failing tests for every allowed extension, blocked/extensionless types, zero/oversize declared and actual bytes, unsafe slugs and original filenames, picker cancellation, missing source, byte-backed Android-style picks, atomic replacement, deletion, and paths remaining under `materials/<slug>`.
- [ ] Run `flutter test test/features/materials/local_material_store_test.dart` and verify the expected missing-store failure.
- [ ] Implement one picker/copy store using generated filenames, temporary copies, actual-size validation, canonical managed-directory checks, and cleanup on failure. Validate replacement before removing its managed predecessor.
- [ ] Re-run the focused store tests.

### Task 3: Controller compatibility and material actions

**Files:**
- Modify: `lib/app/app_controller.dart`
- Modify: `lib/main.dart`
- Test: `test/app/app_controller_test.dart`
- Test: `test/features/animations/local_animation_store_test.dart`

**Interfaces:**
- Consumes: `LocalMaterialStore`, existing `AppState.animationPaths`
- Produces: `materials`, `importAnimation`, `addMaterial`, `replaceMaterial`, `removeMaterial`, `openMaterial`, `materialError`, `importingMaterial`

- [ ] Add failing controller tests proving current-problem isolation, legacy animation exposure, import/reopen/replace/remove persistence, cancellation, errors, and unchanged Run Tests/Submit request data.
- [ ] Run the focused controller and legacy-animation tests and confirm only new expectations fail.
- [ ] Inject `LocalMaterialStore`, retain the existing animation method surface for compatibility, migrate a legacy animation into displayed material metadata without deleting it, and serialize state changes through existing `onSave`.
- [ ] Configure `main.dart` with application-support storage and `OpenFilex.open` result handling for PDF/video. No `file:` URL launcher.
- [ ] Re-run focused controller, animation, and judge tests.

### Task 4: Python highlighting and editor geometry

**Files:**
- Create: `lib/features/workspace/python_code_theme.dart`
- Modify: `lib/features/workspace/workspace_screen.dart`
- Create: `test/features/workspace/python_code_theme_test.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Produces: `pythonCodeTheme` using `re_highlight`'s Python mode and OLT token styles.

- [ ] Write failing tests that render representative keywords, class/function declarations, built-in types, strings, numbers, comments, and operators into distinct styled spans; add widget geometry assertions that editor content starts near its panel's top-left and fills the panel.
- [ ] Run the two focused tests and verify failures.
- [ ] Register the packaged Python mode with `CodeHighlightTheme`, map its token scopes to distinct OLT colors, and add explicit editor padding while preserving the same `CodeLineEditingController`, line numbers, word-wrap setting, and action callbacks.
- [ ] Re-run focused tests and an Android widget text-entry test using `tester.enterText` plus selection/cursor assertions.

### Task 5: Readable problem, notes, materials, results, and responsive UI

**Files:**
- Modify: `lib/core/design/olt_design.dart`
- Modify: `lib/features/workspace/workspace_screen.dart`
- Modify: `lib/features/animations/animation_viewer.dart`
- Create: `lib/features/materials/material_viewer.dart`
- Modify: `test/widget_test.dart`
- Modify: `test/features/animations/animation_viewer_test.dart`
- Create: `test/features/materials/material_viewer_test.dart`

**Interfaces:**
- Produces: internal viewers for image, Markdown, and TXT; external-open error state for PDF/video.
- Produces: shared notes panel with top alignment, 12px padding, placeholder, and character count.

- [ ] Add failing widget tests for problem hierarchy/inline code, scrolling to constraints, notes top-left position and per-problem persistence, attachment metadata/actions, internal image/Markdown/TXT rendering, missing/corrupt fallback, 44px controls, desktop widths, 390x780 portrait, and 780x390 landscape with no overflow.
- [ ] Run focused widget/viewer tests and verify failures correspond to missing UI behavior.
- [ ] Add only necessary OLT text/surface tokens, refactor duplicated notes fields into one top-aligned widget, improve result rows, and build the attachment list with `Import Animation`, `Add Material`, `OPEN`, `REPLACE`, and `REMOVE`.
- [ ] Use `flutter_markdown_plus` with network images and external links disabled; load TXT as selectable local text; reuse `Image.file` for image/animation content; surface external-open failures for PDF/video.
- [ ] Re-run focused widget tests and inspect `tester.takeException()` at each viewport.

### Task 6: Ignore rules and honest Windows validation

**Files:**
- Modify: `.gitignore`
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Create: `.github/workflows/windows.yml`

- [ ] Add ignored runtime material directories/backups/logs without hiding source or tests.
- [ ] Add only `flutter_markdown_plus` and `open_filex`, then run `flutter pub get`.
- [ ] Add `windows-latest` CI steps for `flutter config --enable-windows-desktop`, `flutter pub get`, formatting check, `flutter analyze`, `flutter test`, and `flutter build windows --debug`.
- [ ] Run `dart format --output=none --set-exit-if-changed .` and inspect the workflow syntax.

### Task 7: Full validation, smoke tests, and one commit

**Files:**
- Update only feature-related files if validation exposes defects.

- [ ] Run `dart format .`, `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build linux --debug`, and `flutter build apk --debug`; fix every failure test-first.
- [ ] Launch Linux with `./scripts/start-linux.sh`, capture a workspace screenshot, and manually smoke problem scrolling, editor input/highlighting, notes, attachments, responsive layout, and judge buttons.
- [ ] Run `adb devices`, install the debug APK on `R9ZX30B0CHB`, launch it, exercise portrait and landscape navigation/editing/import/reopen/replace/remove/Run Tests, capture screenshots, and inspect filtered `adb logcat` for crashes, Flutter errors, and overflows.
- [ ] Confirm the Windows workflow is configured but report it as pending unless a real `windows-latest` run succeeds.
- [ ] Audit `git diff`, ensure unrelated untracked files and backups are untouched/un-staged, and verify no judge implementation file changed.
- [ ] Stage only feature files and create the single commit `feat(workspace): improve editor and local learning materials`.
