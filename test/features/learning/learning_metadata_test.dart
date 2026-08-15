import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/problems/problem_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'all bundled problems have three hints and expected complexity',
    () async {
      final problems = await AssetProblemRepository(rootBundle).loadAll();

      expect(problems, hasLength(75));
      for (final problem in problems) {
        expect(problem.hints, hasLength(3), reason: problem.slug);
        expect(problem.hints.every((hint) => hint.trim().isNotEmpty), isTrue);
        expect(problem.expectedTimeComplexity, startsWith('O('));
        expect(problem.expectedSpaceComplexity, startsWith('O('));
        expect(problem.complexityExplanation, isNotEmpty);
      }
    },
  );
}
