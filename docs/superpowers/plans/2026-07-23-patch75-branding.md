# Patch75 Branding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Ship consistently branded Patch75 Linux and Android release apps.

**Architecture:** Preserve all internal identifiers and runtime code. Replace
only visible metadata and icon resources, using the supplied production
artwork and native platform configuration.

**Tech Stack:** Flutter, Dart, GTK/CMake, Android resources, Bash

## Global Constraints

- Preserve unrelated worktree changes, `.backups`, `.logs`, and diagnostics.
- Back up every existing file before changing it.
- Do not change Android or Linux application identifiers.
- Add no icon dependency when supplied assets and native tools cover the work.
- Commit only after all checks and both release builds pass.

---

### Task 1: Backups and visible metadata

**Files:** `pubspec.yaml`, `lib/app/offline_trainer_app.dart`,
`linux/runner/my_application.cc`, `android/app/src/main/AndroidManifest.xml`

- [ ] Back up existing files under a timestamped `.backups` directory.
- [ ] Change visible product names to `Patch75`.
- [ ] Change safe descriptive copy to `Offline Algorithm Trainer`.
- [ ] Run `dart format` on the changed Dart file.

### Task 2: Production icons

**Files:** `assets/branding/patch75.png`, Android `mipmap-*`, `drawable-*`,
`values/colors.xml`, and adaptive icon XML resources.

- [ ] Copy the supplied Linux 512 px PNG and Android legacy/round PNGs.
- [ ] Render adaptive foreground and monochrome SVGs at all five densities.
- [ ] Add native adaptive icon XML and midnight background color.
- [ ] Assert dimensions, transparency, references, and mask-safe source bounds.

### Task 3: User launcher

**Files:** `~/.local/bin/offline-leetcode-trainer`,
`~/.local/share/applications/com.abnzr.offline-leetcode-trainer.desktop`

- [ ] Back up both files before changing them.
- [ ] Update visible name, subtitle, icon, and notifications.
- [ ] Keep absolute release-binary launch behavior and missing-build logging.
- [ ] Validate Bash syntax and desktop-entry fields.

### Task 4: Verification and release builds

- [ ] Run `flutter pub get`, `flutter analyze`, and full `flutter test`.
- [ ] Run branding scans and judge diagnostics.
- [ ] Remove only stale build output via `flutter clean`.
- [ ] Run `flutter build linux --release`.
- [ ] Run `flutter build apk --release`.
- [ ] Re-run targeted final checks and inspect the scoped diff.
- [ ] Commit only the verified branding changes.
