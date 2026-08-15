import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offline_leetcode_trainer/features/judge/judge_models.dart';
import 'package:offline_leetcode_trainer/features/judge/judge_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('embedded Android Python passes, fails, and times out', (
    tester,
  ) async {
    const service = AndroidPythonJudgeService();
    expect(await service.isAvailable(), isTrue);
    const tests = [
      JudgeTestInput(
        id: 'sample-1',
        values: {
          'nums': [8, 6, 11, 3],
          'target': 14,
        },
      ),
    ];

    final passing = await service.run(
      const JudgeRequest(
        problemSlug: 'two-sum',
        language: 'python',
        sourceCode: '''
from typing import List
class Solution:
    def twoSum(self, nums: List[int], target: int) -> List[int]:
        seen = {}
        for index, value in enumerate(nums):
            if target - value in seen:
                return [seen[target - value], index]
            seen[value] = index
        return []
''',
        selectedTests: ['sample-1'],
      ),
      tests,
    );
    expect(passing.status, JudgeStatus.passed);

    final failing = await service.run(
      const JudgeRequest(
        problemSlug: 'two-sum',
        language: 'python',
        sourceCode:
            'class Solution:\n    def twoSum(self, nums, target): return []',
        selectedTests: ['sample-1'],
      ),
      tests,
    );
    expect(failing.status, JudgeStatus.failed);

    final timeout = await service.run(
      const JudgeRequest(
        problemSlug: 'two-sum',
        language: 'python',
        sourceCode:
            'class Solution:\n    def twoSum(self, nums, target):\n        while True: pass',
        selectedTests: ['sample-1'],
      ),
      tests,
    );
    expect(timeout.status, JudgeStatus.timeout);
  });
}
