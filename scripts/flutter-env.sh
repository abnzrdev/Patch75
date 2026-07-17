#!/usr/bin/env bash
export FLUTTER_HOME="$HOME/developer/flutter"
export ANDROID_HOME="/home/abnzr/Projects/qdemmobile/.android-sdk"
export ANDROID_SDK_ROOT="/home/abnzr/Projects/qdemmobile/.android-sdk"
export PATH="$FLUTTER_HOME/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

# Keep local desktop judge traffic away from system proxies.
_append_no_proxy_host() {
  local current="$1"
  local host

  for host in 127.0.0.1 localhost ::1; do
    case ",$current," in
      *",$host,"*) ;;
      *) current="${current:+$current,}$host" ;;
    esac
  done

  printf '%s' "$current"
}

export NO_PROXY="$(_append_no_proxy_host "${NO_PROXY:-}")"
export no_proxy="$(_append_no_proxy_host "${no_proxy:-}")"

unset -f _append_no_proxy_host
