import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/review/fsrs_scheduler_service.dart';
import 'package:offline_leetcode_trainer/features/review/review_repository.dart';
import 'package:offline_leetcode_trainer/features/review/review_models.dart';

void main() {
  test('migrates solved problems once without duplicate cards', () async {
    final repository = LocalReviewRepository(FsrsSchedulerService());
    final now = DateTime.utc(2026, 7, 22);

    final first = await repository.migrateSolved(
      progress: const {'two-sum': 'solved', '3sum': 'attempted'},
      records: const {},
      nowUtc: now,
    );
    final second = await repository.migrateSolved(
      progress: const {'two-sum': 'solved'},
      records: first,
      nowUtc: now.add(const Duration(days: 1)),
    );

    expect(first.keys, ['two-sum']);
    expect(second, first);
  });

  test('queue sorts overdue, due, new, then upcoming', () async {
    final scheduler = FsrsSchedulerService();
    final repository = LocalReviewRepository(scheduler);
    final now = DateTime.utc(2026, 7, 22, 12);
    final overdue = await scheduler.createCard(
      'overdue',
      nowUtc: now.subtract(const Duration(days: 2)),
    );
    final newCard = await scheduler.createCard('new-card', nowUtc: now);
    final rated = await scheduler.rate(
      await scheduler.createCard('due-card', nowUtc: now),
      ReviewRating.good,
      reviewedAtUtc: now.subtract(const Duration(minutes: 20)),
    );
    final upcoming = await scheduler.rate(
      await scheduler.createCard('upcoming', nowUtc: now),
      ReviewRating.easy,
      reviewedAtUtc: now,
    );

    final queue = repository.queue({
      'new-card': newCard,
      'upcoming': upcoming.record,
      'overdue': overdue,
      'due-card': rated.record,
    }, nowUtc: now);

    expect(queue.map((item) => item.bucket), [
      ReviewQueueBucket.overdue,
      ReviewQueueBucket.due,
      ReviewQueueBucket.newCard,
      ReviewQueueBucket.upcoming,
    ]);
  });
}
