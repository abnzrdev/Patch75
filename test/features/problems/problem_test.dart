import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/problems/problem.dart';

void main() {
  test('parses the normalized problem schema', () {
    final problem = Problem.fromJson({
      'id': 1,
      'slug': 'two-sum',
      'title': 'Two Sum',
      'difficulty': 'easy',
      'topics': ['array', 'hash-table'],
      'description': 'Find two indices.',
      'examples': [
        {
          'input': 'nums = [2,7,11,15], target = 9',
          'output': '[0,1]',
          'explanation': '2 + 7 = 9',
        },
      ],
      'constraints': ['2 <= nums.length <= 10^4'],
      'starterCodeByLanguage': {'python': 'class Solution: pass'},
      'testCases': [
        {
          'id': 'sample-1',
          'input': {
            'nums': [2, 7, 11, 15],
            'target': 9,
          },
          'expected': [0, 1],
          'sample': true,
        },
      ],
      'source': 'cojudge',
      'sourceUrl': 'https://github.com/cojudge/cojudge',
    });

    expect(problem.id, 1);
    expect(problem.examples.single.output, '[0,1]');
    expect(problem.starterCodeByLanguage['python'], contains('Solution'));
    expect(problem.testCases.single.input['target'], 9);
  });

  test('rejects invalid problem slugs', () {
    expect(
      () => Problem.fromJson({
        'id': 1,
        'slug': '../two-sum',
        'title': 'Two Sum',
        'difficulty': 'easy',
        'topics': <String>[],
        'description': '',
        'examples': <Object>[],
        'constraints': <String>[],
        'starterCodeByLanguage': <String, String>{},
        'testCases': <Object>[],
        'source': 'cojudge',
        'sourceUrl': 'https://github.com/cojudge/cojudge',
      }),
      throwsFormatException,
    );
  });
}
