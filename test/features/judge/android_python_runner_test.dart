import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android scratch mode exposes print without changing test mode', () async {
    final scratch = await _run({
      'problemSlug': 'two-sum',
      'language': 'python',
      'mode': 'scratch',
      'sourceCode': 'print("hello")',
      'tests': [],
    });
    final tests = await _run({
      'problemSlug': 'two-sum',
      'language': 'python',
      'mode': 'tests',
      'sourceCode':
          'print("debug")\nclass Solution:\n def twoSum(self, nums, target): return [0, 1]',
      'tests': [
        {
          'id': 'sample-1',
          'nums': [8, 6],
          'target': 14,
        },
      ],
    });

    expect(scratch['status'], 'passed');
    expect(scratch['stdout'], 'hello\n');
    expect(tests['status'], 'error');
    expect(tests['stderr'], contains("name 'print' is not defined"));
  });
}

Future<Map<String, Object?>> _run(Map<String, Object?> payload) async {
  final result = await Process.run('python3', [
    '-B',
    '-c',
    '''
import json, sys
sys.path.insert(0, "android/app/src/main/python")
import judge_runner
print(judge_runner.run(${jsonEncode(jsonEncode(payload))}))
''',
  ]);
  expect(result.exitCode, 0, reason: result.stderr as String);
  return Map<String, Object?>.from(jsonDecode(result.stdout as String) as Map);
}
