import contextlib
import io
import json
import time
import typing


def _import(name, globals=None, locals=None, fromlist=(), level=0):
    if name != "typing":
        raise ImportError("Only the typing module is available")
    return typing


SAFE_BUILTINS = {
    "__build_class__": __build_class__,
    "__import__": _import,
    "abs": abs,
    "all": all,
    "any": any,
    "bool": bool,
    "dict": dict,
    "enumerate": enumerate,
    "Exception": Exception,
    "float": float,
    "int": int,
    "isinstance": isinstance,
    "len": len,
    "list": list,
    "max": max,
    "min": min,
    "object": object,
    "range": range,
    "set": set,
    "str": str,
    "sum": sum,
    "tuple": tuple,
    "TypeError": TypeError,
    "ValueError": ValueError,
    "zip": zip,
}


def run(payload_json):
    payload = json.loads(payload_json)
    mode = payload.get("mode", "tests")
    if (
        payload.get("problemSlug") != "two-sum"
        or payload.get("language") != "python"
        or len(payload.get("sourceCode", "").encode()) > 65536
        or mode not in ("scratch", "tests", "submit")
    ):
        raise ValueError("Invalid judge request")
    tests = payload.get("tests", [])
    if mode != "scratch" and not 0 < len(tests) <= 100:
        raise ValueError("Select between 1 and 100 tests")

    captured_out, captured_err = io.StringIO(), io.StringIO()
    results = []
    started = time.perf_counter()
    try:
        builtins = (
            {**SAFE_BUILTINS, "print": print}
            if mode == "scratch"
            else SAFE_BUILTINS
        )
        namespace = {
            "__name__": "submission",
            "__builtins__": builtins,
        }
        with contextlib.redirect_stdout(captured_out), contextlib.redirect_stderr(
            captured_err
        ):
            exec(compile(payload["sourceCode"], "submission.py", "exec"), namespace)
            if mode != "scratch":
                solution = namespace["Solution"]()
                for test in tests:
                    nums, target = test["nums"], test["target"]
                    output = solution.twoSum(list(nums), target)
                    valid = (
                        isinstance(output, list)
                        and len(output) == 2
                        and all(
                            isinstance(index, int) and 0 <= index < len(nums)
                            for index in output
                        )
                        and output[0] != output[1]
                        and nums[output[0]] + nums[output[1]] == target
                    )
                    results.append(
                        {
                            "id": test["id"],
                            "passed": valid,
                            "output": json.dumps(output, separators=(",", ":")),
                            "expected": "two distinct indices whose values sum to target",
                            "error": None if valid else "Wrong Answer",
                        }
                    )
        passed = sum(item["passed"] for item in results)
        status = "passed" if mode == "scratch" or passed == len(results) else "failed"
        error = captured_err.getvalue()
    except Exception as exception:
        passed, status = 0, "error"
        error = captured_err.getvalue() + type(exception).__name__ + ": " + str(exception)
    return json.dumps(
        {
            "status": status,
            "stdout": captured_out.getvalue()[:65536],
            "stderr": error[:65536],
            "executionTimeMs": int((time.perf_counter() - started) * 1000),
            "memoryUsageBytes": None,
            "passedTests": passed,
            "totalTests": len(tests),
            "testResults": results,
        },
        separators=(",", ":"),
    )
