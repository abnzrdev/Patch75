import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/review/review_models.dart';

void main() {
  test('review records serialize every timestamp as UTC', () {
    final created = DateTime.parse('2026-07-22T05:00:00+05:00');
    final record = ReviewRecord(
      id: 'review-two-sum',
      problemSlug: 'two-sum',
      card: const {'state': 1},
      logs: const [],
      nextDueUtc: created,
      lastReviewUtc: null,
      state: 'learning',
      stability: null,
      difficulty: null,
      retrievability: null,
      createdAtUtc: created,
      updatedAtUtc: created,
    );

    final json = record.toJson();

    expect(json['nextDueUtc'], '2026-07-22T00:00:00.000Z');
    expect(json['createdAtUtc'], '2026-07-22T00:00:00.000Z');
    expect(ReviewRecord.fromJson(json), record);
  });

  test('review event IDs are stable and validated', () {
    final event = ReviewEvent(
      id: 'review-two-sum-1753142400000000',
      problemSlug: 'two-sum',
      rating: ReviewRating.good,
      reviewedAtUtc: DateTime.utc(2026, 7, 22),
      dueBeforeUtc: DateTime.utc(2026, 7, 22),
      dueAfterUtc: DateTime.utc(2026, 7, 25),
      fsrsLog: const {'rating': 3},
      createdAtUtc: DateTime.utc(2026, 7, 22),
    );

    expect(ReviewEvent.fromJson(event.toJson()), event);
    expect(
      () => ReviewEvent.fromJson({...event.toJson(), 'id': '../unsafe'}),
      throwsFormatException,
    );
  });
}
