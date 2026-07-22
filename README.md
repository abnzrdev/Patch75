# Offline LeetCode Trainer

Offline-first Blind 75 practice for Flutter desktop and Android. The app bundles
normalized cojudge problem data, keeps drafts/notes/timers/progress in a local
versioned JSON store, runs Python in locked-down Docker containers on desktop,
and embeds Python through Chaquopy on Android.

No account, internet connection, cloud sync, analytics, or Anki is used. Review
scheduling uses the local FSRS algorithm and never contacts a service.

## Feature matrix

| Capability | Linux | Android | Web |
|---|---:|---:|---:|
| Browse all Blind 75 problems | Yes | Yes | Yes |
| Editor, drafts, notes, timer, focus mode | Yes | Yes | Yes |
| Private learning materials and viewers | Yes | Yes | Yes |
| Timed FSRS review queue | Yes | Yes | Yes |
| Versioned progress ZIP export/import | Yes | Yes | Yes |
| Python Run/Submit | Docker bridge | Chaquopy | Unavailable |
| Offline after installation | Yes | Yes | Yes |

LeetCodeAnimation does not publish a redistribution license. Its manifest is
matched locally, but its GIFs and articles are not packaged. The app displays an
explicit missing-media state and supports the viewer controls without claiming
that unlicensed media is included.

## Requirements

- Flutter 3.44.6 / Dart 3.12.2
- Linux desktop toolchain
- Android SDK 36 and Java 21 for Android builds
- Docker for desktop execution only
- An authorized Android API 24+ device for physical-device tests

Load the project environment before every Flutter command:

```bash
source scripts/flutter-env.sh
flutter pub get
```

## Run on Linux

```bash
source scripts/flutter-env.sh
docker pull python:3.13-alpine
scripts/start-desktop-judge.sh
```

In another terminal:

```bash
source scripts/flutter-env.sh
flutter run -d linux
```

Browsing and studying still work if Docker or the bridge is stopped.

## Build and install Android

```bash
source scripts/flutter-env.sh
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Android executes Python 3.11 in a non-exported separate service process. A
seven-second host watchdog kills that process on timeout. This reduces impact
but is not a secure sandbox for hostile Python.

See [Android setup](docs/ANDROID_SETUP.md) and
[desktop judge](docs/DESKTOP_JUDGE.md).

## Rebuild local data

External repositories are ignored by Git:

```bash
git clone --depth 1 https://github.com/cojudge/cojudge .cache/external/cojudge
git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/MisterBooo/LeetCodeAnimation \
  .cache/external/LeetCodeAnimation
git -C .cache/external/LeetCodeAnimation sparse-checkout set docs/data

source scripts/flutter-env.sh
dart run tool/import_cojudge.dart
dart run tool/import_animations.dart
```

The cojudge importer writes 75 normalized records plus a combined startup
bundle. The animation importer writes metadata only; it never copies upstream
media. Attribution and exact inspected revisions are in
[third-party sources](docs/THIRD_PARTY.md).

## Verification

```bash
source scripts/flutter-env.sh
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter analyze
flutter test
flutter build linux
flutter build apk --debug
flutter build web
flutter test integration_test/android_python_judge_test.dart -d DEVICE_SERIAL
```

Chrome is not required to build web output. Browser runtime testing was not
performed in the recorded environment because Chrome is absent.

See [security](docs/SECURITY.md), [performance](docs/PERFORMANCE.md), and
[architecture](docs/ARCHITECTURE.md) for measured results and limitations.
Review behavior is documented in [FSRS review](docs/FSRS_REVIEW.md); archive
validation and merge rules are in [export format](docs/EXPORT_FORMAT.md).
