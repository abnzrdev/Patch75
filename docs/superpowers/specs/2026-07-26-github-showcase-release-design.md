# Patch75 GitHub Showcase and v1.0.0 Release Design

## Goal

Present Patch75 professionally on its private GitHub repository, publish verified
Linux and Android v1.0.0 artifacts, and validate the downloaded Linux release
locally.

## Visual Direction

Use the existing `assets/branding/patch75.png` as the unchanged master logo.
The README begins with a clearly displayed copy of that logo, followed by a
1280×640 dark industrial hero that matches the application UI. The hero combines
the official logo, one Linux workspace screenshot, two Android screenshot crops,
and restrained lime accents. It introduces no replacement logo or generated
brand mark.

Use the seven tracked screenshots in `screenshots/verification/` for the gallery.
Promote an ignored runtime screenshot only if a required feature is otherwise
missing and only after checking it for usernames, filesystem paths, tokens, and
private data. All README images use repository-relative paths under
`docs/images/`.

## README Content

The README contains:

- official Patch75 logo and graphical hero;
- concise product statement and v1.0.0 download links;
- feature highlights covering offline Blind 75 practice, editor and notes,
  Run Code, Run Tests, review scheduling, and local progress;
- Linux and Android screenshot gallery;
- Linux, Android, and Web capability table;
- explicit local-first privacy and platform security limitations;
- Linux and Android installation steps plus Linux uninstall instructions;
- development prerequisites and required verification commands;
- direct GitHub Release asset links for the Linux archive, APK, and checksums.

## Repository Metadata

Keep `abnzrdev/Patch75` private. Update only its description and focused topics
for Flutter, offline learning, algorithms, Python, Linux, and Android. Configure
the 1280×640 hero as the GitHub social preview when supported by available
authenticated tooling.

## Packaging and Safety

Back up each existing file before editing under the ignored `.backups/`
directory. Do not commit backups, build directories, secrets, signing material,
or local runtime state.

Package the complete `build/linux/x64/release/bundle` directory as
`Patch75-linux-x86_64-v1.0.0.tar.gz`. Include safe install and uninstall scripts
that operate only on explicit Patch75 paths beneath the invoking user's local
directories and preserve user application state on uninstall. Copy the release
APK as `Patch75-android-v1.0.0.apk`. Build an Android App Bundle for verification
but do not publish it because the requested release assets name only the Linux
archive and APK. Generate SHA-256 checksums for every published artifact and
verify them before upload and after download.

## Verification and Release Flow

Run formatting in check mode, `flutter analyze`, all Flutter tests, Linux release
build, Android release APK build, and Android release AAB build in that order.
Stop before commit, merge, tag, or release if any required check fails.

After successful checks:

1. Commit only intended showcase, packaging, and documentation files.
2. Push `docs/github-showcase` and create or update its pull request.
3. Confirm required GitHub checks pass, then merge into the default branch.
4. Tag the merge commit as `v1.0.0`.
5. Create a draft release, upload and inspect the Linux archive, APK, install and
   uninstall scripts, and checksum manifest, then publish.
6. Download the published assets from GitHub and verify the checksum manifest.
7. Install the Linux release locally and smoke-test launch, icon integration,
   editor, notes, Run Code, Run Tests, Two Sum, and Counting Bits.

Android device testing is reported as skipped unless an authorized connected
device is available. Existing user state is preserved throughout installation
and validation.

## Failure Handling

Any required local check or GitHub check failure stops the release workflow.
Asset checksum mismatch stops installation and publication. Missing capability
in the installed application is reported without masking or weakening the
validation.
