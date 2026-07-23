import 'dart:convert';

import 'judge_models.dart';

const dockerImage = 'python:3.13-alpine';

List<String> dockerArguments(String containerName) => [
  'run',
  '--rm',
  '--name',
  containerName,
  '--network',
  'none',
  '--cap-drop',
  'ALL',
  '--security-opt',
  'no-new-privileges',
  '--read-only',
  '--tmpfs',
  '/tmp:rw,noexec,nosuid,size=16m',
  '--memory',
  '128m',
  '--memory-swap',
  '128m',
  '--pids-limit',
  '64',
  '--cpus',
  '0.5',
  '--user',
  '65534:65534',
  '-i',
  dockerImage,
  'timeout',
  '3',
  'python',
  '-I',
  '-B',
  '-c',
  pythonHarness,
];

String dockerPayload(JudgeRequest request, List<JudgeTestInput> tests) {
  request.validate();
  return jsonEncode({
    'mode': request.mode.name,
    'sourceCode': request.sourceCode,
    'tests': tests.map((test) => test.toJson()).toList(),
  });
}

const pythonHarness = r'''
import contextlib, io, json, sys, time
payload = json.load(sys.stdin)
source = payload["sourceCode"]
mode = payload["mode"]
tests = payload["tests"]
captured_out, captured_err = io.StringIO(), io.StringIO()
results = []
started = time.perf_counter()
try:
    namespace = {"__name__": "submission"}
    with contextlib.redirect_stdout(captured_out), contextlib.redirect_stderr(captured_err):
        exec(compile(source, "submission.py", "exec"), namespace)
        if mode != "scratch":
            solution = namespace["Solution"]()
            for test in tests:
                nums, target = test["nums"], test["target"]
                try:
                    output = solution.twoSum(list(nums), target)
                    valid = (
                        isinstance(output, list) and len(output) == 2 and
                        all(isinstance(i, int) and 0 <= i < len(nums) for i in output) and
                        output[0] != output[1] and nums[output[0]] + nums[output[1]] == target
                    )
                    results.append({
                        "id": test["id"], "passed": valid,
                        "output": json.dumps(output, separators=(",", ":")),
                        "expected": "two distinct indices whose values sum to target",
                        "error": None if valid else "Wrong Answer"
                    })
                except Exception as error:
                    results.append({
                        "id": test["id"], "passed": False, "output": "",
                        "expected": "two distinct indices whose values sum to target",
                        "error": type(error).__name__ + ": " + str(error)
                    })
    passed = sum(item["passed"] for item in results)
    print(json.dumps({
        "status": "passed" if mode == "scratch" or passed == len(results) else "failed",
        "stdout": captured_out.getvalue()[:65536],
        "stderr": captured_err.getvalue()[:65536],
        "executionTimeMs": int((time.perf_counter() - started) * 1000),
        "memoryUsageBytes": None, "passedTests": passed,
        "totalTests": len(results), "testResults": results
    }, separators=(",", ":")))
except Exception as error:
    print(json.dumps({
        "status": "error", "stdout": captured_out.getvalue()[:65536],
        "stderr": (captured_err.getvalue() + type(error).__name__ + ": " + str(error))[:65536],
        "executionTimeMs": int((time.perf_counter() - started) * 1000),
        "memoryUsageBytes": None, "passedTests": 0,
        "totalTests": len(tests), "testResults": []
    }, separators=(",", ":")))
''';
