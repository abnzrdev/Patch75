import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/animations/animation_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the generated license-safe animation index', () async {
    final entries = await AssetAnimationRepository(rootBundle).loadAll();
    final twoSum = entries.singleWhere((entry) => entry.slug == 'two-sum');

    expect(twoSum.problemId, 1);
    expect(twoSum.relativePath, isNull);
  });
}
