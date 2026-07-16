#!/usr/bin/env bash
set -u

cd /home/abnzr/Projects/offline-leetcode-trainer-flutter || exit 1
source scripts/flutter-env.sh

echo "Flutter: $(flutter --version | head -1)"
echo "Starting Codex with Flutter environment..."
exec codex
