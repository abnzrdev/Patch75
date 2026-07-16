import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:offline_leetcode_trainer/features/judge/judge_models.dart';
import 'package:offline_leetcode_trainer/features/judge/judge_service.dart';

void main() {
  test('desktop service posts structured requests only to loopback', () async {
    http.Request? sent;
    final service = DesktopCojudgeJudgeService(
      client: MockClient((request) async {
        sent = request;
        return http.Response(
          jsonEncode({
            'status': 'passed',
            'stdout': '',
            'stderr': '',
            'executionTimeMs': 7,
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
          }),
          200,
        );
      }),
    );

    final result = await service.run(
      const JudgeRequest(
        problemSlug: 'two-sum',
        language: 'python',
        sourceCode: 'class Solution: pass',
        selectedTests: ['sample-1'],
      ),
      const [
        JudgeTestInput(
          id: 'sample-1',
          values: {
            'nums': [2, 7],
            'target': 9,
          },
        ),
      ],
    );

    expect(sent!.url.host, '127.0.0.1');
    expect(sent!.url.port, 5376);
    expect(jsonDecode(sent!.body), containsPair('problemSlug', 'two-sum'));
    expect(result.status, JudgeStatus.passed);
  });
}
