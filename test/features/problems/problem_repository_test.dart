import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/problems/problem_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads all 75 bundled problems in Blind 75 order', () async {
    final problems = await AssetProblemRepository(rootBundle).loadAll();

    expect(problems, hasLength(75));
    expect(problems.first.slug, '3sum');
    expect(problems.any((problem) => problem.slug == 'two-sum'), isTrue);
  });
}
