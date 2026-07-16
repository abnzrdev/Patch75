import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/animations/animation_entry.dart';

void main() {
  test('matches animation by id before normalized text', () {
    const entry = AnimationEntry(
      problemId: 1,
      slug: 'different-slug',
      title: 'Different title',
      relativePath: 'problems/0001/Animation.gif',
      sourceUrl: 'https://github.com/MisterBooo/LeetCodeAnimation',
    );

    expect(entry.matches(id: 1, slug: 'two-sum', title: 'Two Sum'), isTrue);
  });

  test('normalizes punctuation when matching slug or title', () {
    const entry = AnimationEntry(
      problemId: 99,
      slug: 'two_sum',
      title: 'Two Sum!',
      relativePath: null,
      sourceUrl: 'https://github.com/MisterBooo/LeetCodeAnimation',
    );

    expect(entry.matches(id: 1, slug: 'Two Sum', title: 'Other'), isTrue);
  });

  test('parses license-safe manifest entries without bundled media', () {
    final entry = AnimationEntry.fromJson({
      'problemId': 1,
      'slug': 'two-sum',
      'title': 'Two Sum',
      'relativePath': null,
      'sourceUrl': 'https://github.com/MisterBooo/LeetCodeAnimation',
    });

    expect(entry.problemId, 1);
    expect(entry.relativePath, isNull);
  });
}
