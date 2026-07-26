#!/usr/bin/env bash
set -u

PROJECT="/home/abnzr/Projects/offline-leetcode-trainer-flutter"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="$PROJECT/docs/judge-diagnostic-$STAMP.log"
PROBE="$PROJECT/tool/.judge_probe_$$.dart"

cd "$PROJECT" || {
  echo "Error: project folder not found."
  exit 1
}

mkdir -p docs tool

cleanup() {
  rm -f "$PROBE"
}
trap cleanup EXIT

exec > >(tee "$LOG") 2>&1

echo "Offline LeetCode Trainer — Judge Diagnostic"
echo "Generated: $(date --iso-8601=seconds)"
echo

echo "===== 1. Environment ====="
source scripts/flutter-env.sh || echo "Warning: Flutter environment could not be loaded."

echo "User: $(whoami)"
echo "Branch: $(git branch --show-current 2>/dev/null || echo unknown)"
echo "Flutter: $(flutter --version 2>/dev/null | head -1 || echo missing)"
echo "Dart: $(dart --version 2>&1 || echo missing)"
echo

echo "Proxy variables:"
env | grep -iE '^(http|https|all|no)_proxy=' || echo "No proxy variables found."
echo

echo "===== 2. Judge process and port ====="
ps -ef | grep -E '[d]esktop_judge|[s]tart-desktop-judge' || echo "Judge process not found."
echo

if command -v ss >/dev/null 2>&1; then
  ss -ltnp | grep ':5376' || echo "Nothing is listening on TCP port 5376."
else
  echo "ss command not available."
fi
echo

echo "===== 3. Curl probes ====="
CURL_STATUS=0

for host in 127.0.0.1 localhost; do
  echo
  echo "GET http://$host:5376/health"
  if ! curl --noproxy '*' -fsS --max-time 3 \
      "http://$host:5376/health"; then
    CURL_STATUS=1
    echo "Curl probe failed for $host."
  fi
  echo
done

echo
echo "===== 4. Dart package:http probe ====="

cat > "$PROBE" <<'DART'
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

Future<bool> packageHttpProbe(Uri uri) async {
  stdout.writeln('package:http GET $uri');
  stdout.writeln(
    'Proxy decision: ${HttpClient.findProxyFromEnvironment(uri)}',
  );

  try {
    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 4));

    stdout.writeln('Status: ${response.statusCode}');
    stdout.writeln('Body: ${response.body}');

    return response.statusCode == 200 &&
        response.body.contains('"status":"ok"');
  } catch (error, stackTrace) {
    stderr.writeln('package:http error: $error');
    stderr.writeln(stackTrace);
    return false;
  }
}

Future<bool> directHttpClientProbe(Uri uri) async {
  stdout.writeln('\ndart:io DIRECT GET $uri');

  final client = HttpClient()
    ..findProxy = (_) => 'DIRECT'
    ..connectionTimeout = const Duration(seconds: 4);

  try {
    final request = await client.getUrl(uri);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    stdout.writeln('Status: ${response.statusCode}');
    stdout.writeln('Body: $body');

    return response.statusCode == 200 &&
        body.contains('"status":"ok"');
  } catch (error, stackTrace) {
    stderr.writeln('dart:io error: $error');
    stderr.writeln(stackTrace);
    return false;
  } finally {
    client.close(force: true);
  }
}

Future<void> main() async {
  final uri = Uri.parse('http://127.0.0.1:5376/health');

  final packageOk = await packageHttpProbe(uri);
  final directOk = await directHttpClientProbe(uri);

  stdout.writeln('\npackage:http result: ${packageOk ? "PASS" : "FAIL"}');
  stdout.writeln('direct dart:io result: ${directOk ? "PASS" : "FAIL"}');

  if (!packageOk || !directOk) {
    exitCode = 2;
  }
}
DART

dart run "$PROBE"
DART_STATUS=$?

echo
echo "===== 5. Dart probe with localhost excluded from proxies ====="

NO_PROXY="127.0.0.1,localhost,::1" \
no_proxy="127.0.0.1,localhost,::1" \
dart run "$PROBE"
NO_PROXY_DART_STATUS=$?

echo
echo "===== 6. Judge service selection and initialization ====="

grep -RInE \
  'DesktopCojudgeJudgeService|AndroidPythonJudgeService|UnsupportedJudgeService|JudgeService|judgeAvailable|/health|5376|JUDGE/UNAVAILABLE' \
  lib \
  --exclude='*.g.dart' \
  2>/dev/null || true

echo
echo "===== 7. Relevant source files ====="

for file in \
  lib/features/judge/judge_service.dart \
  lib/app/app_controller.dart \
  lib/features/workspace/workspace_screen.dart \
  lib/main.dart
do
  if [ -f "$file" ]; then
    echo
    echo "----- $file -----"
    nl -ba "$file" | sed -n '1,360p'
  fi
done

echo
echo "===== 8. Judge-related unit tests ====="

mapfile -t JUDGE_TESTS < <(
  find test -type f -name '*_test.dart' 2>/dev/null |
  while read -r file; do
    if grep -qiE 'judge|health|DesktopCojudge' "$file"; then
      echo "$file"
    fi
  done
)

if [ "${#JUDGE_TESTS[@]}" -gt 0 ]; then
  printf 'Running:\n'
  printf '  %s\n' "${JUDGE_TESTS[@]}"
  flutter test "${JUDGE_TESTS[@]}"
  TEST_STATUS=$?
else
  echo "No judge-specific unit tests found."
  TEST_STATUS=0
fi

echo
echo "===== DIAGNOSIS ====="

if [ "$CURL_STATUS" -eq 0 ] &&
   [ "$DART_STATUS" -eq 0 ] &&
   [ "$NO_PROXY_DART_STATUS" -eq 0 ]; then
  echo "Backend and Dart HTTP access both work."
  echo "Most likely area: judge service selection or AppController state initialization."
  echo "Check the source section above for UnsupportedJudgeService or a cached availability result."
elif [ "$CURL_STATUS" -eq 0 ] &&
     [ "$DART_STATUS" -ne 0 ] &&
     [ "$NO_PROXY_DART_STATUS" -eq 0 ]; then
  echo "Proxy environment is blocking the Dart localhost request."
  echo "The app launcher should set NO_PROXY=127.0.0.1,localhost,::1."
elif [ "$CURL_STATUS" -eq 0 ] &&
     [ "$DART_STATUS" -ne 0 ]; then
  echo "Curl reaches the judge, but Dart package:http does not."
  echo "Review the Dart exception and proxy decision above."
else
  echo "The judge was not consistently reachable on port 5376."
  echo "Check the process, listener, and curl sections above."
fi

echo
echo "===== RECAP ====="
echo "Changed:"
echo "- Created one diagnostic log: $LOG"
echo "- Temporary Dart probe was removed automatically"
echo
echo "Project source files changed: none"
echo
echo "Test status: $TEST_STATUS"
echo "Next: send the DIAGNOSIS section and the lines around service selection."
