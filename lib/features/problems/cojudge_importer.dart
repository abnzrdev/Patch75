import 'dart:convert';

Map<String, Object?> normalizeCojudgeProblem({
  required String slug,
  required String statement,
  required Map<String, Object?> metadata,
  required List<Object?> tests,
}) {
  final titleWithId = metadata['title'] as String;
  final match = RegExp(r'^(\d+)\.\s*(.+)$').firstMatch(titleWithId);
  if (match == null) throw const FormatException('Missing LeetCode ID');
  final sections = statement.split(RegExp(r'\n\s*\*\*Constraints:\*\*\s*\n'));
  final constraints = sections.length == 1
      ? <String>[]
      : sections[1]
            .split('\n')
            .map((line) => line.replaceFirst(RegExp(r'^\s*-\s*'), '').trim())
            .where((line) => line.isNotEmpty)
            .toList();

  return {
    'id': int.parse(match.group(1)!),
    'slug': slug,
    'title': match.group(2)!,
    'difficulty': (metadata['difficulty'] as String).toLowerCase(),
    'topics': [metadata['category'] as String],
    'description': sections.first.trim(),
    'examples': metadata['examples'],
    'constraints': constraints,
    'starterCodeByLanguage': metadata['starterCode'],
    'testCases': [
      for (final (index, test) in tests.indexed)
        _normalizeTwoSumTest(index, test as Map<String, Object?>),
    ],
    'source': 'cojudge',
    'sourceUrl': 'https://github.com/cojudge/cojudge',
  };
}

Map<String, Object?> _normalizeTwoSumTest(
  int index,
  Map<String, Object?> test,
) {
  final nums = _parseNums(test['nums'] as String);
  final target = test['target'] as int;
  return {
    'id': index < 3 ? 'sample-${index + 1}' : 'official-${index + 1}',
    'input': {'nums': nums, 'target': target},
    'expected': _twoSum(nums, target),
    'sample': index < 3,
  };
}

List<int> _parseNums(String value) {
  if (value.startsWith('@javascript:')) {
    final match = RegExp(
      r'^@javascript:JSON\.stringify\(\[\.\.\.Array\((\d+)\)\.fill\((-?\d+)\),\s*(-?\d+),\s*(-?\d+)\]\)$',
    ).firstMatch(value);
    if (match == null) throw const FormatException('Unsafe dynamic test data');
    final count = int.parse(match.group(1)!);
    if (count > 10000) throw const FormatException('Test input too large');
    return [
      ...List.filled(count, int.parse(match.group(2)!)),
      int.parse(match.group(3)!),
      int.parse(match.group(4)!),
    ];
  }
  return List<int>.from(jsonDecode(value) as List);
}

List<int> _twoSum(List<int> nums, int target) {
  final seen = <int, int>{};
  for (final (index, value) in nums.indexed) {
    final other = seen[target - value];
    if (other != null) return [other, index];
    seen[value] = index;
  }
  return [];
}
