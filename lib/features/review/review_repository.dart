import 'fsrs_scheduler_service.dart';
import 'review_models.dart';

enum ReviewQueueBucket { overdue, due, newCard, upcoming }

class ReviewQueueItem {
  const ReviewQueueItem({required this.record, required this.bucket});

  final ReviewRecord record;
  final ReviewQueueBucket bucket;
}

abstract interface class ReviewRepository {
  Future<Map<String, ReviewRecord>> migrateSolved({
    required Map<String, String> progress,
    required Map<String, ReviewRecord> records,
    required DateTime nowUtc,
  });

  List<ReviewQueueItem> queue(
    Map<String, ReviewRecord> records, {
    required DateTime nowUtc,
  });
}

class LocalReviewRepository implements ReviewRepository {
  const LocalReviewRepository(this.scheduler);

  final ReviewSchedulerService scheduler;

  @override
  Future<Map<String, ReviewRecord>> migrateSolved({
    required Map<String, String> progress,
    required Map<String, ReviewRecord> records,
    required DateTime nowUtc,
  }) async {
    final migrated = {...records};
    for (final entry in progress.entries) {
      if (entry.value == 'solved' && !migrated.containsKey(entry.key)) {
        migrated[entry.key] = await scheduler.createCard(
          entry.key,
          nowUtc: nowUtc,
        );
      }
    }
    return migrated;
  }

  @override
  List<ReviewQueueItem> queue(
    Map<String, ReviewRecord> records, {
    required DateTime nowUtc,
  }) {
    final now = nowUtc.toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final values = [
      for (final record in records.values)
        ReviewQueueItem(record: record, bucket: _bucket(record, now, today)),
    ];
    values.sort((left, right) {
      final priority = left.bucket.index.compareTo(right.bucket.index);
      return priority != 0
          ? priority
          : left.record.nextDueUtc.compareTo(right.record.nextDueUtc);
    });
    return values;
  }

  ReviewQueueBucket _bucket(ReviewRecord record, DateTime now, DateTime today) {
    if (record.nextDueUtc.isBefore(today)) return ReviewQueueBucket.overdue;
    if (record.logs.isEmpty) return ReviewQueueBucket.newCard;
    if (!record.nextDueUtc.isAfter(now)) return ReviewQueueBucket.due;
    return ReviewQueueBucket.upcoming;
  }
}
