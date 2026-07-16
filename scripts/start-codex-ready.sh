#!/usr/bin/env bash
set -u

cd "/home/abnzr/Projects/offline-leetcode-trainer-flutter" || {
  echo "Project folder not found: /home/abnzr/Projects/offline-leetcode-trainer-flutter"
  exit 1
}

export SUPERPOWERS_DISABLE_TELEMETRY=1
export PONYTAIL_DEFAULT_MODE="${PONYTAIL_DEFAULT_MODE:-full}"

echo "Starting Codex for Offline LeetCode Trainer..."
echo
echo "Before the first development task, check:"
echo "  /plugins  -> Superpowers and Ponytail"
echo "  /mcp      -> Context7 and CodeGraph"
echo "  /hooks    -> review and trust expected plugin hooks"
echo
echo "Do not trust unknown hook commands."
echo

exec codex
