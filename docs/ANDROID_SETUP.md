# Android Setup

## Build

```bash
source scripts/flutter-env.sh
flutter doctor -v
adb devices -l
flutter build apk --debug
```

An authorized device is shown with the exact state `device`, not
`unauthorized` or `offline`.

Install:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## Offline Python

Chaquopy 17.0 packages Python 3.11 for Android API 24+. The app manifest exports
only the launcher activity. `PythonJudgeService` is non-exported and runs in
`:python_judge`, a separate process with the app UID. It accepts bounded JSON
over Android Messenger IPC and returns a structured result over MethodChannel.

The runner:

- accepts only Two Sum and Python;
- caps source at 64 KiB and the IPC payload/result at 256 KiB;
- exposes only a restricted builtins set and allows only `typing` imports;
- captures and truncates stdout/stderr;
- rejects concurrent runs;
- kills the service process after seven seconds.

This is defense in depth, not a hostile-code sandbox. The Python process retains
the app UID, Android APIs may still be reachable through creative runtime
techniques, and CPython resource accounting is not a security boundary. The app
contains no credentials or private user data and requests no runtime
permissions.

## Physical-device test

```bash
source scripts/flutter-env.sh
flutter test integration_test/android_python_judge_test.dart -d R9ZX30B0CHB
```

The recorded Samsung SM-M145F/API 35 run covered passing output, wrong answer,
and an infinite loop terminated as timeout.

