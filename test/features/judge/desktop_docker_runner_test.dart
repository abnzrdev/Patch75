import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/judge/desktop_docker_runner.dart';
import 'package:offline_leetcode_trainer/features/judge/judge_models.dart';

void main() {
  test('builds a locked-down Docker argument array without source code', () {
    const request = JudgeRequest(
      problemSlug: 'two-sum',
      language: 'python',
      sourceCode: r'dangerous $(touch /tmp/host)',
      selectedTests: ['sample-1'],
    );

    final arguments = dockerArguments('olt-123');

    expect(arguments, containsAllInOrder(['run', '--rm', '--name', 'olt-123']));
    expect(arguments, containsAll(['--network', 'none']));
    expect(arguments, containsAll(['--cap-drop', 'ALL']));
    expect(arguments, contains('--read-only'));
    expect(arguments, containsAll(['--pids-limit', '64']));
    expect(arguments, containsAll(['--memory', '128m']));
    expect(arguments.join(' '), isNot(contains(request.sourceCode)));
    expect(arguments.join(' '), isNot(contains('-v ')));
  });

  test('encodes only validated structured input for the container', () {
    const request = JudgeRequest(
      problemSlug: 'two-sum',
      language: 'python',
      sourceCode: 'class Solution: pass',
      selectedTests: ['sample-1'],
    );
    final payload = dockerPayload(request, [
      const JudgeTestInput(
        id: 'sample-1',
        values: {
          'nums': [8, 6],
          'target': 14,
        },
      ),
    ]);

    expect(payload, contains('"sourceCode":"class Solution: pass"'));
    expect(payload, contains('"id":"sample-1"'));
  });

  test('scratch mode executes freeform Python and captures stdout', () async {
    const request = JudgeRequest(
      problemSlug: 'two-sum',
      language: 'python',
      sourceCode: 'print("hello")',
      selectedTests: [],
      mode: JudgeMode.scratch,
    );

    final result = await _runHarness(dockerPayload(request, const []));

    expect(result['status'], 'passed');
    expect(result['stdout'], 'hello\n');
    expect(result['stderr'], isEmpty);
    expect(result['totalTests'], 0);
  });

  test('scratch mode reports syntax and runtime errors', () async {
    for (final source in ['print(', 'raise ValueError("broken")']) {
      final result = await _runHarness(
        dockerPayload(
          JudgeRequest(
            problemSlug: 'two-sum',
            language: 'python',
            sourceCode: source,
            selectedTests: const [],
            mode: JudgeMode.scratch,
          ),
          const [],
        ),
      );

      expect(result['status'], 'error');
      expect(result['stderr'], isNotEmpty);
    }
  });
}

Future<Map<String, Object?>> _runHarness(String payload) async {
  final process = await Process.start('python3', [
    '-I',
    '-B',
    '-c',
    pythonHarness,
  ]);
  process.stdin.write(payload);
  await process.stdin.close();
  final output = await utf8.decoder.bind(process.stdout).join();
  final errors = await utf8.decoder.bind(process.stderr).join();
  expect(await process.exitCode, 0, reason: errors);
  return Map<String, Object?>.from(jsonDecode(output) as Map);
}
