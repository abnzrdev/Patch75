import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:offline_leetcode_trainer/features/judge/judge_models.dart';
import 'package:offline_leetcode_trainer/features/judge/judge_service.dart';

void main() {
  test('desktop service blocks submit before contacting the bridge', () async {
    var calls = 0;

    final service = DesktopDockerJudgeService(
      client: MockClient((request) async {
        calls++;
        throw StateError('unsafe backend must not be contacted');
      }),
    );

    final result = await service.run(
      const JudgeRequest(
        problemSlug: 'counting-bits',
        language: 'python',
        sourceCode: 'class Solution: pass',
        selectedTests: ['official-1'],
        mode: JudgeMode.submit,
      ),
      const [],
    );

    expect(calls, 0);
    expect(result.status, JudgeStatus.unavailable);
    expect(result.stderr, contains('disabled'));
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
