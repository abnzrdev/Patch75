#!/usr/bin/env bash
set -euo pipefail

data_home="${XDG_DATA_HOME:-${HOME:?HOME is required}/.local/share}"
bin_home="${XDG_BIN_HOME:-$HOME/.local/bin}"
install_dir="$data_home/patch75"
launcher="$bin_home/patch75"
desktop_file="$data_home/applications/dev.abnzr.patch75.desktop"
state_dir="$data_home/dev.abnzr.offline_leetcode_trainer"

[[ "$data_home" != / && -n "$data_home" ]] ||
  { echo "Refusing unsafe XDG data directory." >&2; exit 1; }

rm -f -- "$launcher" "$desktop_file"
rm -rf -- "$install_dir"

echo "Patch75 uninstalled."
echo "User data preserved at: $state_dir"
