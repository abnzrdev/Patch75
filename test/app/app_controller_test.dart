import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/app/app_controller.dart';
import 'package:offline_leetcode_trainer/core/storage/app_state.dart';
import 'package:offline_leetcode_trainer/features/judge/judge_models.dart';
import 'package:offline_leetcode_trainer/features/judge/judge_service.dart';
import 'package:offline_leetcode_trainer/features/problems/problem.dart';

void main() {
  test('runs sample tests and exposes the structured result', () async {
    final controller = AppController(
      problem: Problem.fromJson(
        jsonDecode(_problemJson) as Map<String, Object?>,
      ),
      state: const AppState(),
      judgeService: _PassingJudge(),
    );
    addTearDown(controller.dispose);

    await controller.runTests(submit: false);

    expect(controller.judgeResult?.status, JudgeStatus.passed);
    expect(controller.judgeResult?.passedTests, 1);
    expect(controller.judging, isFalse);
    expect(controller.state.testHistory['two-sum'], ['passed:1/1']);
  });
}

class _PassingJudge implements JudgeService {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<JudgeResult> run(
    JudgeRequest request,
    List<JudgeTestInput> tests,
  ) async => JudgeResult(
    status: JudgeStatus.passed,
    stdout: '',
    stderr: '',
    executionTimeMs: 4,
    memoryUsageBytes: null,
    passedTests: tests.length,
    totalTests: tests.length,
    testResults: [
      for (final test in tests)
        JudgeTestResult(
          id: test.id,
          passed: true,
          output: '[0,1]',
          expected: '[0,1]',
          error: null,
        ),
    ],
  );
}

const _problemJson = r'''
{
  "id": 1,
  "slug": "two-sum",
  "title": "Two Sum",
  "difficulty": "easy",
  "topics": ["array"],
  "description": "Find indices.",
  "examples": [],
  "constraints": [],
  "starterCodeByLanguage": {"python":"class Solution: pass"},
  "testCases": [{"id":"sample-1","input":{"nums":[2,7],"target":9},"expected":[0,1],"sample":true}],
  "source": "cojudge",
  "sourceUrl": "https://github.com/cojudge/cojudge"
}
''';
