import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/custom_tests/custom_test_case.dart';
import 'package:offline_leetcode_trainer/features/custom_tests/custom_test_repository.dart';

void main() {
  final now = DateTime.utc(2026, 7, 22);

  test('validates stable IDs, JSON, required fields, types, and sizes', () {
    final repository = LocalCustomTestRepository(
      requiredFields: const {'nums': List, 'target': int},
    );
    final valid = CustomTestCase.create(
      id: 'custom-two-sum-1',
      problemSlug: 'two-sum',
      name: 'negatives',
      input: const {
        'nums': [-1, 4],
        'target': 3,
      },
      nowUtc: now,
    );

    expect(repository.validate(valid), isNull);
    expect(repository.parseAdvancedJson('{"nums":[2,7],"target":9}'), {
      'nums': [2, 7],
      'target': 9,
    });
    expect(() => repository.parseAdvancedJson('{bad'), throwsFormatException);
    expect(
      repository.validate(
        valid.copyWith(
          input: const {
            'nums': [1],
          },
        ),
      ),
      contains('target'),
    );
    expect(
      () => CustomTestCase.create(
        id: '../bad',
        problemSlug: 'two-sum',
        name: 'bad',
        input: const {},
        nowUtc: now,
      ),
      throwsArgumentError,
    );
  });

  test('supports save, edit, duplicate, delete, enable, and reorder', () {
    final repository = LocalCustomTestRepository(requiredFields: const {});
    final first = CustomTestCase.create(
      id: 'custom-two-sum-1',
      problemSlug: 'two-sum',
      name: 'first',
      input: const {
        'nums': [1],
        'target': 1,
      },
      nowUtc: now,
    );
    var values = repository.save(const [], first);
    values = repository.save(values, first.copyWith(name: 'edited'));
    values = repository.duplicate(values, first.id, nowUtc: now);
    expect(values, hasLength(2));
    values = repository.reorder(values, 1, 0);
    values = repository.toggle(values, values.first.id, false, nowUtc: now);
    expect(values.first.enabled, isFalse);
    values = repository.delete(values, values.last.id);
    expect(values, hasLength(1));
  });

  test('enforces maximum test count', () {
    final repository = LocalCustomTestRepository(
      requiredFields: const {},
      maxTests: 2,
    );
    final values = [
      for (var i = 0; i < 2; i++)
        CustomTestCase.create(
          id: 'custom-two-sum-$i',
          problemSlug: 'two-sum',
          name: '$i',
          input: const {},
          nowUtc: now,
        ),
    ];
    expect(
      () => repository.save(
        values,
        CustomTestCase.create(
          id: 'custom-two-sum-3',
          problemSlug: 'two-sum',
          name: '3',
          input: const {},
          nowUtc: now,
        ),
      ),
      throwsStateError,
    );
  });
}
