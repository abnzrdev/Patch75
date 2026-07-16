import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/judge/judge_models.dart';

void main() {
  test('accepts a bounded Python request for an allowed problem', () {
    const request = JudgeRequest(
      problemSlug: 'two-sum',
      language: 'python',
      sourceCode: 'class Solution: pass',
      selectedTests: ['sample-1'],
    );

    expect(() => request.validate(), returnsNormally);
  });

  test('rejects traversal, unsupported languages, and oversized code', () {
    expect(
      () => const JudgeRequest(
        problemSlug: '../two-sum',
        language: 'python',
        sourceCode: 'pass',
        selectedTests: [],
      ).validate(),
      throwsArgumentError,
    );
    expect(
      () => const JudgeRequest(
        problemSlug: 'two-sum',
        language: 'bash',
        sourceCode: 'echo pwned',
        selectedTests: [],
      ).validate(),
      throwsArgumentError,
    );
    expect(
      () => JudgeRequest(
        problemSlug: 'two-sum',
        language: 'python',
        sourceCode: 'x' * (JudgeRequest.maxSourceBytes + 1),
        selectedTests: const [],
      ).validate(),
      throwsArgumentError,
    );
  });

  test('truncates judge output by UTF-8 byte budget', () {
    expect(truncateOutput('abcdefgh', 5), 'abcde');
    expect(truncateOutput('🙂🙂', 5), '🙂');
  });
}
