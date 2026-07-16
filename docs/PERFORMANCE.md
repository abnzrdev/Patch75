# Performance Report

Measured 2026-07-16 on Zorin OS 18.1, AMD Radeon/Renoir host, Flutter 3.44.6,
Dart 3.12.2, Docker 29.5.2, and Samsung SM-M145F Android 15/API 35 over USB.

## Results

| Check | Result |
|---|---:|
| Android profile cold start after install | 3,670 ms |
| Android profile subsequent force-stop cold starts | 1,463 ms; 1,397 ms |
| Android debug cold starts | 4,976–5,259 ms |
| Android debug warm activity resume | 8–11 ms |
| Decode/check combined 75-record JSON 100 times with jq | 0.86 s |
| 100 Docker passing runs | 59.67 s total (597 ms/run mean) |
| One passing Docker run, two tests | 841 ms |
| One wrong-answer Docker run | 542 ms |
| Infinite-loop Docker run | terminated at 6.01 s host watchdog |
| 50 concurrent requested state writes | serialized; final value preserved |
| Combined problem bundle | 388 KiB |
| Linux release bundle | 26 MiB |
| Android profile APK | 113.2 MiB |
| Android debug APK | 201 MiB |
| Web build directory | 42 MiB |

Commands used included `adb shell am start -W`, `/usr/bin/time`, 100
localhost bridge requests validated with `jq`, and the automated state-store
stress test.

## Findings

- Combining 75 generated records into one startup asset avoids 75 platform
  channel reads. Profile startup is acceptable after installation, but the
  first launch remains 3.67 seconds on the tested phone.
- Chaquopy and multiple native ABIs dominate APK size. ABI-split release
  artifacts are the next size optimization; the universal debug APK is kept for
  development convenience.
- Container startup dominates desktop judge latency. The implementation avoids a
  long-lived shared container because per-run isolation is more important than
  sub-500 ms latency for this local trainer.
- The viewer packages no GIF media, so animation memory stress currently covers
  missing/corrupt and repeated expanded-view lifecycle, not large decoded GIFs.

## Remaining tests

Release-mode frame timing, low-memory Android process death, a licensed large
GIF, Windows/macOS builds, and GPU memory traces were not available in this
environment. No performance claim is made for them.

