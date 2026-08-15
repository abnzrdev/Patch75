import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/judge/judge_models.dart';
import 'package:offline_leetcode_trainer/features/judge/judge_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(AndroidPythonJudgeService.channelName);

  test('android service exchanges a bounded structured result', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'run');
          final request = jsonDecode(call.arguments as String) as Map;
          expect(request['problemSlug'], 'two-sum');
          expect(request['mode'], 'scratch');
          return jsonEncode({
            'status': 'passed',
            'stdout': '',
            'stderr': '',
            'executionTimeMs': 5,
            'memoryUsageBytes': null,
            'passedTests': 1,
            'totalTests': 1,
            'testResults': [
              {
                'id': 'sample-1',
                'passed': true,
                'output': '[0,1]',
                'expected': '[0,1]',
                'error': null,
              },
            ],
          });
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    final result = await const AndroidPythonJudgeService().run(
      const JudgeRequest(
        problemSlug: 'two-sum',
        language: 'python',
        sourceCode: 'print("hello")',
        selectedTests: [],
        mode: JudgeMode.scratch,
      ),
      const [
        JudgeTestInput(
          id: 'sample-1',
          values: {
            'nums': [8, 6],
            'target': 14,
          },
        ),
      ],
    );

    expect(result.status, JudgeStatus.passed);
  });

  test('android service maps process termination to timeout', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) => throw PlatformException(
            code: 'PYTHON_JUDGE',
            message: 'Time Limit Exceeded',
          ),
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    final result = await const AndroidPythonJudgeService().run(
      const JudgeRequest(
        problemSlug: 'two-sum',
        language: 'python',
        sourceCode: 'while True: pass',
        selectedTests: ['sample-1'],
      ),
      const [
        JudgeTestInput(
          id: 'sample-1',
          values: {
            'nums': [8, 6],
            'target': 14,
          },
        ),
      ],
    );

    expect(result.status, JudgeStatus.timeout);
  });
}
