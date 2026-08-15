#!/usr/bin/env bash
export FLUTTER_HOME="${FLUTTER_HOME:-$HOME/developer/flutter}"
export PATH="$FLUTTER_HOME/bin:$PATH"

if [[ -n "${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}" ]]; then
  export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"
  export ANDROID_HOME="${ANDROID_HOME:-$ANDROID_SDK_ROOT}"
  export PATH="$ANDROID_SDK_ROOT/platform-tools:$PATH"
fi

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
