#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/flutter-env.sh
exec dart run tool/desktop_judge/server.dart
