import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/problems/problem_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads all 75 original Patch75 problems in curriculum order', () async {
    final problems = await AssetProblemRepository(rootBundle).loadAll();

    expect(problems, hasLength(75));
    expect(problems.first.slug, '3sum');
    expect(problems.any((problem) => problem.slug == 'two-sum'), isTrue);
    for (final problem in problems) {
      expect(problem.source, 'Patch75', reason: problem.slug);
      expect(problem.sourceUrl, isEmpty, reason: problem.slug);
      expect(problem.license, 'AGPL-3.0-only', reason: problem.slug);
      expect(problem.originalContent, isTrue, reason: problem.slug);
      expect(problem.description.trim(), isNotEmpty, reason: problem.slug);
      expect(problem.examples, isNotEmpty, reason: problem.slug);
      expect(problem.constraints, isNotEmpty, reason: problem.slug);
      expect(
        problem.starterCodeByLanguage['python'],
        isNotEmpty,
        reason: problem.slug,
      );
      expect(
        problem.testCases.length,
        greaterThanOrEqualTo(2),
        reason: problem.slug,
      );
      expect(problem.hints, isNotEmpty, reason: problem.slug);
    }
  });
}
