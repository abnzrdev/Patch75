import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/problems/cojudge_importer.dart';

void main() {
  test('normalizes cojudge Two Sum metadata and tests', () {
    final result = normalizeCojudgeProblem(
      slug: 'two-sum',
      statement:
          'Given nums, find two indices.\n\n**Constraints:**\n- 2 <= nums.length',
      metadata: {
        'title': '1. Two Sum',
        'difficulty': 'Easy',
        'link': 'https://leetcode.com/problems/two-sum/',
        'category': 'array',
        'examples': [
          {'input': 'nums = [2,7], target = 9', 'output': '[0,1]'},
        ],
        'starterCode': {'python': 'class Solution: pass'},
      },
      tests: [
        {'nums': '[2,7]', 'target': 9},
      ],
    );

    expect(result['id'], 1);
    expect(result['title'], 'Two Sum');
    expect(result['description'], 'Given nums, find two indices.');
    expect(result['constraints'], ['2 <= nums.length']);
    expect(
      (result['testCases'] as List).single,
      containsPair('expected', [0, 1]),
    );
  });
}
