#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
source scripts/flutter-env.sh

for command in docker dart; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Error: required command '$command' was not found."
        exit 1
    fi
done

if ! docker info >/dev/null 2>&1; then
    echo "Error: Docker is not running or is not accessible."
    exit 1
fi

exec dart run tool/desktop_judge/server.dart
