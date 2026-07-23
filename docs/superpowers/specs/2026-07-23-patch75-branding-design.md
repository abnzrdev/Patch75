# Patch75 Branding Design

## Goal

Apply the supplied Patch75 production branding to Flutter, Linux, Android, and
the user's desktop launcher without changing internal identifiers or runtime
workflows.

## Design

- Keep `offline_leetcode_trainer` and `dev.abnzr.offline_leetcode_trainer` as
  internal package, binary, and application identifiers.
- Use `Patch75` as the visible product name and `Offline Algorithm Trainer` as
  descriptive copy.
- Copy the supplied production legacy Android icons and Linux 512 px icon.
- Convert the supplied 108 dp adaptive SVG artwork into density-specific PNGs,
  with `#0B0D17` as the native adaptive background color.
- Add native adaptive, round, and Android 13 monochrome resource references;
  add no Flutter icon-generation dependency.
- Keep the launcher release-only, absolute-path based, and logged. Back up both
  user launcher files before changing them.

## Verification

Run Dart formatting, dependency resolution, static analysis, all Flutter tests,
branding/resource assertions, judge diagnostics, clean Linux release build, and
clean Android release APK build. Commit only after every required check passes.
