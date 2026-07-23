import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:offline_leetcode_trainer/features/judge/judge_models.dart';
import 'package:offline_leetcode_trainer/features/judge/judge_service.dart';

void main() {
  test('desktop service forwards submit mode to Cojudge bridge', () async {
    Map<String, dynamic>? body;

    final service = DesktopCojudgeJudgeService(
      client: MockClient((request) async {
        body = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({
            'status': 'passed',
            'stdout': '',
            'stderr': '',
            'executionTimeMs': 1,
            'memoryUsageBytes': null,
            'passedTests': 1,
            'totalTests': 1,
            'testResults': [
              {
                'id': 'official-1',
                'passed': true,
                'output': '[0]',
                'expected': '[0]',
                'error': null,
              },
            ],
          }),
          200,
        );
      }),
    );

    await service.run(
      const JudgeRequest(
        problemSlug: 'counting-bits',
        language: 'python',
        sourceCode: 'class Solution: pass',
        selectedTests: ['official-1'],
        mode: JudgeMode.submit,
      ),
      const [],
    );

    expect(body, isNotNull);
    expect(body!['problemSlug'], 'counting-bits');
    expect(body!['submit'], isTrue);
  });

  test('JudgeRequest defaults to sample-test mode', () {
    const request = JudgeRequest(
      problemSlug: 'two-sum',
      language: 'python',
      sourceCode: 'class Solution: pass',
      selectedTests: ['sample-1'],
    );

    expect(request.submit, isFalse);
  });
}
