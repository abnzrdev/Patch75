#!/usr/bin/env bash
set -euo pipefail

source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
data_home="${XDG_DATA_HOME:-${HOME:?HOME is required}/.local/share}"
bin_home="${XDG_BIN_HOME:-$HOME/.local/bin}"
install_dir="$data_home/patch75"
applications_dir="$data_home/applications"
launcher="$bin_home/patch75"
desktop_file="$applications_dir/dev.abnzr.patch75.desktop"

[[ -x "$source_dir/offline_leetcode_trainer" ]] ||
  { echo "Missing Patch75 executable in $source_dir" >&2; exit 1; }
[[ -f "$source_dir/patch75-logo.png" ]] ||
  { echo "Missing Patch75 logo in $source_dir" >&2; exit 1; }
[[ "$data_home" != / && -n "$data_home" ]] ||
  { echo "Refusing unsafe XDG data directory." >&2; exit 1; }

mkdir -p "$data_home" "$bin_home" "$applications_dir"
stage="$(mktemp -d "$data_home/.patch75-install.XXXXXX")"
previous=""

cleanup() {
  rm -rf -- "$stage"
  if [[ -n "$previous" && -d "$previous" && ! -e "$install_dir" ]]; then
    mv -- "$previous" "$install_dir"
  fi
}
trap cleanup EXIT

cp -a -- "$source_dir/." "$stage/app"
if [[ -e "$install_dir" ]]; then
  previous="$data_home/.patch75-previous.$$"
  [[ ! -e "$previous" ]] || { echo "Backup path already exists." >&2; exit 1; }
  mv -- "$install_dir" "$previous"
fi
mv -- "$stage/app" "$install_dir"

ln -sfn -- "$install_dir/offline_leetcode_trainer" "$launcher"
{
  echo "[Desktop Entry]"
  echo "Version=1.0"
  echo "Type=Application"
  echo "Name=Patch75"
  echo "GenericName=Offline Algorithm Trainer"
  echo "Comment=Practice 75 algorithm exercises offline"
  printf 'Exec="%s"\n' "$install_dir/offline_leetcode_trainer"
  printf 'TryExec="%s"\n' "$install_dir/offline_leetcode_trainer"
  printf 'Icon=%s\n' "$install_dir/patch75-logo.png"
  echo "Terminal=false"
  echo "Categories=Education;Development;"
  echo "StartupNotify=true"
} >"$desktop_file"
chmod 0644 "$desktop_file"

if [[ -n "$previous" ]]; then
  rm -rf -- "$previous"
  previous=""
fi

echo "Patch75 installed. Run: $launcher"
