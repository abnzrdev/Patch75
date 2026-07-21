import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/review/fsrs_scheduler_service.dart';
import 'package:offline_leetcode_trainer/features/review/review_models.dart';

void main() {
  final now = DateTime.utc(2026, 7, 22, 12);

  test('creates one reviewable FSRS card with UTC due date', () async {
    final service = FsrsSchedulerService(desiredRetention: 0.90);

    final record = await service.createCard('two-sum', nowUtc: now);

    expect(record.id, 'review-two-sum');
    expect(record.problemSlug, 'two-sum');
    expect(record.nextDueUtc.isUtc, isTrue);
    expect(record.card, isNotEmpty);
  });

  for (final rating in ReviewRating.values) {
    test(
      '${rating.name} creates an immutable event and advances card',
      () async {
        final service = FsrsSchedulerService(desiredRetention: 0.90);
        final record = await service.createCard('two-sum', nowUtc: now);

        final result = await service.rate(
          record,
          rating,
          reviewedAtUtc: now.add(const Duration(minutes: 5)),
        );

        expect(result.record.logs, hasLength(1));
        expect(result.record.logs.single.rating, rating);
        expect(result.record.nextDueUtc.isAfter(now), isTrue);
        expect(result.nextInterval, isNot(Duration.zero));
      },
    );
  }

  test('rejects unsafe retention values', () {
    expect(
      () => FsrsSchedulerService(desiredRetention: 0.69),
      throwsArgumentError,
    );
    expect(
      () => FsrsSchedulerService(desiredRetention: 1),
      throwsArgumentError,
    );
  });
}
