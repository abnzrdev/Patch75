#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COJUDGE_DIR="${COJUDGE_DIR:-$ROOT/.cache/external/cojudge}"
COJUDGE_PORT="${COJUDGE_PORT:-5375}"
COJUDGE_LOG="$ROOT/.logs/cojudge.log"

cd "$ROOT"
source scripts/flutter-env.sh

export NO_PROXY="127.0.0.1,localhost,::1${NO_PROXY:+,$NO_PROXY}"
export no_proxy="127.0.0.1,localhost,::1${no_proxy:+,$no_proxy}"
export COJUDGE_DIR
export COJUDGE_PORT

mkdir -p "$ROOT/.logs"

if [[ ! -d "$COJUDGE_DIR/problems" ]]; then
    echo "Error: Cojudge repository is missing: $COJUDGE_DIR"
    exit 1
fi

for command in node npm docker dart curl; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Error: required command '$command' was not found."
        exit 1
    fi
done

if ! docker info >/dev/null 2>&1; then
    echo "Error: Docker is not running or is not accessible."
    exit 1
fi

# BEGIN OLT COJUDGE BUILD
echo "Preparing Cojudge dependencies and build..."

(
    cd "$COJUDGE_DIR"

    if [[ ! -d node_modules ]]; then
        if [[ -f package-lock.json ]]; then
            npm ci
        else
            npm install
        fi
    fi

    if [[ ! -f .svelte-kit/output/server/manifest.js ]]; then
        npm run build
    fi

    if [[ ! -f .svelte-kit/output/server/manifest.js ]]; then
        echo "Error: Cojudge build output is still missing."
        exit 1
    fi
)
# END OLT COJUDGE BUILD

COJUDGE_STARTED="no"
COJUDGE_PID=""
BRIDGE_PID=""

cleanup() {
    status=$?
    set +e

    if [[ -n "$BRIDGE_PID" ]] && kill -0 "$BRIDGE_PID" 2>/dev/null; then
        kill "$BRIDGE_PID" 2>/dev/null
        wait "$BRIDGE_PID" 2>/dev/null
    fi

    if [[ "$COJUDGE_STARTED" == "yes" && -n "$COJUDGE_PID" ]]; then
        kill -- "-$COJUDGE_PID" 2>/dev/null || kill "$COJUDGE_PID" 2>/dev/null
        wait "$COJUDGE_PID" 2>/dev/null
    fi

    exit "$status"
}

trap cleanup EXIT INT TERM

if curl --noproxy "*" -fsS --max-time 3 \
    "http://127.0.0.1:$COJUDGE_PORT/api/image/status?language=python" \
    >/dev/null 2>&1; then
    echo "Cojudge is already running at http://127.0.0.1:$COJUDGE_PORT"
else
    echo "Starting official Cojudge backend..."

    (
        cd "$COJUDGE_DIR"
        exec setsid env PORT="$COJUDGE_PORT" bash ./run.sh
    ) >"$COJUDGE_LOG" 2>&1 &

    COJUDGE_PID=$!
    COJUDGE_STARTED="yes"
    ready="no"

    for attempt in $(seq 1 180); do
        if curl --noproxy "*" -fsS --max-time 3 \
            "http://127.0.0.1:$COJUDGE_PORT/api/image/status?language=python" \
            >/dev/null 2>&1; then
            ready="yes"
            break
        fi

        if ! kill -0 "$COJUDGE_PID" 2>/dev/null; then
            echo "Error: Cojudge stopped unexpectedly."
            tail -n 60 "$COJUDGE_LOG" 2>/dev/null || true
            exit 1
        fi

        printf "Waiting for Cojudge... %s/180\r" "$attempt"
        sleep 1
    done

    echo

    if [[ "$ready" != "yes" ]]; then
        echo "Error: Cojudge did not become ready."
        tail -n 60 "$COJUDGE_LOG" 2>/dev/null || true
        exit 1
    fi
fi

echo "Starting Flutter judge bridge on http://127.0.0.1:5376..."

dart run tool/desktop_judge/server.dart &
BRIDGE_PID=$!

wait "$BRIDGE_PID"
