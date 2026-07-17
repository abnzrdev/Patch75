#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

JUDGE_URL="http://127.0.0.1:5376"
JUDGE_LOG="$ROOT/.logs/desktop-judge.log"
JUDGE_PID=""
JUDGE_STARTED="no"
APP_STARTED="no"

finish() {
    status=$?
    set +e

    if [[ "$JUDGE_STARTED" == "yes" && -n "$JUDGE_PID" ]]; then
        if kill -0 "$JUDGE_PID" 2>/dev/null; then
            kill -- "-$JUDGE_PID" 2>/dev/null || kill "$JUDGE_PID" 2>/dev/null
            wait "$JUDGE_PID" 2>/dev/null
        fi
    fi

    echo
    echo "========== Recap =========="
    echo "Project: $ROOT"
    echo "Files changed: none"
    echo "Judge log: $JUDGE_LOG"
    echo "Flutter launched: $APP_STARTED"
    echo "Exit status: $status"
    echo "Next: run ./scripts/start-linux.sh again when needed."
    echo "==========================="

    return "$status"
}

trap finish EXIT

for command in flutter curl; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Error: required command '$command' was not found."
        exit 1
    fi
done

if [[ ! -f scripts/flutter-env.sh ]]; then
    echo "Error: scripts/flutter-env.sh was not found."
    exit 1
fi

if [[ ! -x scripts/start-desktop-judge.sh ]]; then
    echo "Error: scripts/start-desktop-judge.sh is missing or not executable."
    exit 1
fi

source scripts/flutter-env.sh

export NO_PROXY="127.0.0.1,localhost,::1${NO_PROXY:+,$NO_PROXY}"
export no_proxy="127.0.0.1,localhost,::1${no_proxy:+,$no_proxy}"

mkdir -p "$ROOT/.logs"

if curl --noproxy "*" -fsS "$JUDGE_URL/health" >/dev/null 2>&1; then
    echo "Judge is already running at $JUDGE_URL"
else
    echo "Starting desktop judge..."

    setsid ./scripts/start-desktop-judge.sh >"$JUDGE_LOG" 2>&1 &
    JUDGE_PID=$!
    JUDGE_STARTED="yes"

    judge_ready="no"

    for attempt in $(seq 1 600); do
        if curl --noproxy "*" -fsS "$JUDGE_URL/health" >/dev/null 2>&1; then
            judge_ready="yes"
            break
        fi

        printf "Waiting for judge... %s/600\r" "$attempt"
        sleep 1
    done

    echo

    if [[ "$judge_ready" != "yes" ]]; then
        echo "Error: judge did not become ready."
        echo "Last judge log lines:"
        tail -n 30 "$JUDGE_LOG" 2>/dev/null || true
        exit 1
    fi

    echo "Judge is ready at $JUDGE_URL"
fi

echo "Starting Flutter Linux app..."
APP_STARTED="yes"

set +e
flutter run -d linux
flutter_status=$?
set -e

exit "$flutter_status"
