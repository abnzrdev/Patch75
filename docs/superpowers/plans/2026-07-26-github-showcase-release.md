# Patch75 GitHub Showcase and v1.0.0 Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish a professional private GitHub showcase and verified Patch75 v1.0.0 Linux and Android release.

**Architecture:** Reuse the official logo and tracked screenshots in a small repository-relative image set, keep packaging in two auditable shell scripts, and gate all GitHub publication on fresh local and remote checks. Release artifacts are generated only from fresh release builds and verified twice with SHA-256.

**Tech Stack:** Flutter 3.44.x, Dart 3.12.2, Bash, Git, GitHub CLI, PNG assets

## Global Constraints

- Keep `abnzrdev/Patch75` private.
- Keep `assets/branding/patch75.png` unchanged as the master logo.
- Back up every existing edited file under ignored `.backups/`.
- Never commit secrets, backups, build output, signing material, or runtime state.
- Use repository-relative README image paths.
- Stop before commit, merge, tag, or release if a required check fails.
- Preserve existing local application state during install and uninstall.

---

### Task 1: README Images and Copy

**Files:**
- Modify: `README.md`
- Create: `docs/images/patch75-logo.png`
- Create: `docs/images/patch75-hero.png`
- Create: `docs/images/linux-workspace.png`
- Create: `docs/images/linux-focus.png`
- Create: `docs/images/linux-animation-expanded.png`
- Create: `docs/images/android-problem.png`
- Create: `docs/images/android-editor.png`
- Create: `docs/images/android-results.png`
- Create: `docs/images/android-animation.png`

**Interfaces:**
- Consumes: `assets/branding/patch75.png`, `screenshots/verification/*.png`
- Produces: repository-relative README presentation assets

- [ ] **Step 1: Back up README**

Run:

```bash
mkdir -p .backups/github-showcase-20260726
cp -p README.md .backups/github-showcase-20260726/README.md
```

- [ ] **Step 2: Copy approved source assets**

Copy the master logo and seven tracked screenshots byte-for-byte into
`docs/images/`; confirm the original logo hash is unchanged afterward.

- [ ] **Step 3: Compose the hero**

Create an exact 1280×640 PNG with the official logo prominent on the left, the
Linux workspace as the primary product frame, two Android screenshot crops as
supporting panels, and the existing black/white/lime application palette. Do not
generate or redraw a logo.

- [ ] **Step 4: Rewrite README**

Add the approved title treatment, hero, v1.0.0 release links, feature highlights,
gallery, platform matrix, privacy/security notes, installation, uninstall,
development requirements, and verification commands.

- [ ] **Step 5: Validate documentation**

Run:

```bash
test "$(file docs/images/patch75-hero.png | sed -n 's/.*PNG image data, \([0-9]* x [0-9]*\).*/\1/p')" = "1280 x 640"
test "$(sha256sum assets/branding/patch75.png | cut -d' ' -f1)" = "$(git show HEAD:assets/branding/patch75.png | sha256sum | cut -d' ' -f1)"
rg -o 'docs/images/[^") ]+' README.md | while read -r image; do test -f "$image"; done
git diff --check
```

### Task 2: Safe Linux Packaging Scripts

**Files:**
- Create: `scripts/install-linux.sh`
- Create: `scripts/uninstall-linux.sh`

**Interfaces:**
- Consumes: an extracted Patch75 Linux bundle beside the scripts
- Produces: installation beneath `${XDG_DATA_HOME:-$HOME/.local/share}/patch75`,
  launcher beneath `${XDG_BIN_HOME:-$HOME/.local/bin}`, and desktop entry beneath
  `${XDG_DATA_HOME:-$HOME/.local/share}/applications`

- [ ] **Step 1: Implement installer**

Use `set -euo pipefail`, resolve the script directory, validate the bundled
executable and icon, copy into a temporary destination, atomically replace only
the explicit Patch75 install directory, install a launcher symlink, and write a
desktop entry with resolved absolute paths. Do not read or delete app state.

- [ ] **Step 2: Implement uninstaller**

Use `set -euo pipefail`; remove only the known launcher, desktop entry, and
installed application bundle. Preserve Patch75 user state and print its location.

- [ ] **Step 3: Check script safety**

Run:

```bash
bash -n scripts/install-linux.sh scripts/uninstall-linux.sh
shellcheck scripts/install-linux.sh scripts/uninstall-linux.sh
```

If `shellcheck` is unavailable, report that check as unavailable and manually
inspect quoted variables and removal targets before continuing.

### Task 3: Required Flutter Verification

**Files:**
- Generated only under ignored `build/`

**Interfaces:**
- Consumes: current committed and intended source tree
- Produces: verified Linux bundle, APK, and AAB

- [ ] **Step 1: Resolve dependencies and check formatting**

Run:

```bash
source scripts/flutter-env.sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test integration_test tool
```

- [ ] **Step 2: Run static analysis**

Run: `source scripts/flutter-env.sh && flutter analyze`

- [ ] **Step 3: Run all tests**

Run: `source scripts/flutter-env.sh && flutter test`

- [ ] **Step 4: Build Linux release**

Run: `source scripts/flutter-env.sh && flutter build linux --release`

- [ ] **Step 5: Build Android APK**

Run: `source scripts/flutter-env.sh && flutter build apk --release`

- [ ] **Step 6: Build Android App Bundle**

Run: `source scripts/flutter-env.sh && flutter build appbundle --release`

Stop the workflow immediately on any non-zero exit.

### Task 4: Release Artifacts and Checksums

**Files:**
- Generated outside Git tracking in a temporary staging directory

**Interfaces:**
- Consumes: fresh Task 3 build outputs and packaging scripts
- Produces: `Patch75-linux-x86_64-v1.0.0.tar.gz`,
  `Patch75-android-v1.0.0.apk`, `install-linux.sh`, `uninstall-linux.sh`,
  `SHA256SUMS`

- [ ] **Step 1: Stage the Linux bundle**

Copy the complete Linux bundle plus install/uninstall scripts and
`docs/images/patch75-logo.png` into a temporary `Patch75/` directory.

- [ ] **Step 2: Archive Linux**

Run `tar -czf Patch75-linux-x86_64-v1.0.0.tar.gz Patch75` from the staging
directory and inspect the archive listing for expected libraries and data.

- [ ] **Step 3: Copy Android APK**

Copy `build/app/outputs/flutter-apk/app-release.apk` to
`Patch75-android-v1.0.0.apk`.

- [ ] **Step 4: Create and verify checksums**

Run:

```bash
sha256sum Patch75-linux-x86_64-v1.0.0.tar.gz Patch75-android-v1.0.0.apk install-linux.sh uninstall-linux.sh > SHA256SUMS
sha256sum -c SHA256SUMS
```

### Task 5: Commit and GitHub Metadata

**Files:**
- Commit only `README.md`, `docs/images/`, `scripts/install-linux.sh`,
  `scripts/uninstall-linux.sh`, and Superpowers design/plan documents

**Interfaces:**
- Consumes: verified intended diff
- Produces: pushed `docs/github-showcase` and private repository metadata

- [ ] **Step 1: Audit the commit scope**

Run `git status --short`, `git diff --check`, `git diff --stat`, and inspect the
full diff. Confirm no ignored or sensitive files are staged.

- [ ] **Step 2: Commit**

Explicitly stage intended paths and commit with
`docs: create Patch75 GitHub showcase`.

- [ ] **Step 3: Update metadata without visibility**

Run:

```bash
gh repo edit abnzrdev/Patch75 \
  --description "Patch75 — private, offline Blind 75 algorithm trainer for Linux and Android" \
  --add-topic flutter --add-topic dart --add-topic algorithms \
  --add-topic leetcode --add-topic offline-first --add-topic linux \
  --add-topic android --add-topic python
```

Then query repository visibility and fail unless it remains `PRIVATE`.

- [ ] **Step 4: Push branch and create or update PR**

Push `docs/github-showcase`, discover an existing PR for that head, and create
one if absent with the validation results in its body.

### Task 6: Merge, Tag, and Publish Release

**Files:**
- GitHub PR, tag, and release state

**Interfaces:**
- Consumes: passing PR checks and verified Task 4 assets
- Produces: merged default branch, `v1.0.0`, and published GitHub Release

- [ ] **Step 1: Verify PR checks**

Run `gh pr checks --watch --fail-fast`; stop on failure.

- [ ] **Step 2: Merge**

Merge the PR through GitHub, confirm the resulting merge commit belongs to the
remote default branch, and update the local default branch without discarding
user work.

- [ ] **Step 3: Tag**

Create annotated tag `v1.0.0` on the verified merge commit and push it.

- [ ] **Step 4: Create draft release**

Create a draft release with Linux and Android installation notes, security
limitations, and an honest Android-device testing statement. Upload all five
Task 4 assets.

- [ ] **Step 5: Verify and publish**

Query the draft release asset names and sizes, download them to a clean temporary
directory, verify `SHA256SUMS`, then publish the draft.

### Task 7: Published Release Installation and Smoke Test

**Files:**
- Temporary download directory and local user installation only

**Interfaces:**
- Consumes: published v1.0.0 assets from GitHub
- Produces: checksum and application smoke-test evidence

- [ ] **Step 1: Download published release**

Use `gh release download v1.0.0 -R abnzrdev/Patch75` into a fresh temporary
directory and run `sha256sum -c SHA256SUMS`.

- [ ] **Step 2: Install**

Extract the Linux archive and run its `install-linux.sh`. Confirm the launcher,
desktop file, icon, executable, libraries, and Flutter assets exist.

- [ ] **Step 3: Launch**

Launch through the installed executable, wait for a visible application window,
and capture logs and process state. Stop if launch fails.

- [ ] **Step 4: Exercise features**

Using available desktop automation, open Two Sum and Counting Bits, edit code and
notes, run code, and run tests. Record concrete UI/output evidence for each.

- [ ] **Step 5: Report Android device coverage**

Run `adb devices`; perform no device tests unless an authorized device is
connected. Report Android-device tests as skipped otherwise.

- [ ] **Step 6: Final audit**

Confirm repository privacy, merged PR, tag target, published release state,
asset names and checksums, clean intended Git status, and preserved user state.
