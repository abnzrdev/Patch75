# Offline LeetCode Trainer

## Goal

Build a cross-platform Flutter learning application by integrating ideas and
data from two open-source projects:

1. cojudge/cojudge
   - Problem statements and test cases
   - Desktop code execution and judging
   - Existing Blind 75 content

2. MisterBooo/LeetCodeAnimation
   - Problem animation manifest
   - Local GIF/image assets
   - Visual explanations

## Current scope

- Flutter UI for Android, Linux, Windows, macOS, iOS, and web
- Problem browser
- Problem-solving workspace
- Timer and focus mode
- Expandable animation viewer
- Local progress and notes

## Platform execution plan

### Desktop

Use a local bridge to the cojudge Docker-based judge.

### Android

Start with offline Python execution using an embedded/local runtime.
Do not depend on Docker on Android.

### Web and iOS

Support studying, editing code, animations, notes, and progress first.
Code execution can use a remote judge later when online.

## Not included yet

- Anki
- FSRS
- Accounts
- Cloud synchronization

## Source repositories

- https://github.com/cojudge/cojudge
- https://github.com/MisterBooo/LeetCodeAnimation

Keep external source checkouts outside Git tracking until their integration
and licensing requirements are reviewed.
