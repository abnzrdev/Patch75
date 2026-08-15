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
          'input': 'nums = [8,6,11,3], target = 14',
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
            'nums': [8, 6, 11, 3],
            'target': 14,
          },
          'expected': [0, 1],
          'sample': true,
        },
      ],
      'source': 'Patch75',
      'sourceUrl': '',
      'license': 'AGPL-3.0-only',
      'originalContent': true,
    });

    expect(problem.id, 1);
    expect(problem.examples.single.output, '[0,1]');
    expect(problem.starterCodeByLanguage['python'], contains('Solution'));
    expect(problem.testCases.single.input['target'], 14);
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
        'source': 'Patch75',
        'sourceUrl': '',
        'license': 'AGPL-3.0-only',
        'originalContent': true,
      }),
      throwsFormatException,
    );
  });
}
