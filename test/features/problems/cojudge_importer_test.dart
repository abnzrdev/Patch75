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

  test('normalizes non-Two-Sum cases without inventing expected output', () {
    final result = normalizeCojudgeProblem(
      slug: 'contains-duplicate',
      statement: 'Detect duplicates.',
      metadata: {
        'title': '3. Contains Duplicate',
        'difficulty': 'Easy',
        'link': 'https://leetcode.com/problems/contains-duplicate/',
        'category': 'array',
        'examples': <Object?>[],
        'starterCode': {'python': 'class Solution: pass'},
      },
      tests: [
        {'nums': '[1,2,1]'},
      ],
    );

    final test = (result['testCases'] as List).single as Map;
    expect(test['input'], {
      'nums': [1, 2, 1],
    });
    expect(test['expected'], isNull);
  });
}
