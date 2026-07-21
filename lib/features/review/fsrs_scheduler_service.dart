import 'package:fsrs/fsrs.dart' as fsrs;

import 'review_models.dart';

class ReviewScheduleResult {
  const ReviewScheduleResult({
    required this.record,
    required this.nextInterval,
  });

  final ReviewRecord record;
  final Duration nextInterval;
}

abstract interface class ReviewSchedulerService {
  Future<ReviewRecord> createCard(String problemSlug, {DateTime? nowUtc});

  Future<ReviewScheduleResult> rate(
    ReviewRecord record,
    ReviewRating rating, {
    required DateTime reviewedAtUtc,
    int? reviewDurationMs,
  });
}

class FsrsSchedulerService implements ReviewSchedulerService {
  FsrsSchedulerService({this.desiredRetention = 0.90}) {
    if (desiredRetention < 0.70 || desiredRetention > 0.99) {
      throw ArgumentError.value(desiredRetention, 'desiredRetention');
    }
    _scheduler = fsrs.Scheduler(
      desiredRetention: desiredRetention,
      enableFuzzing: false,
    );
  }

  final double desiredRetention;
  late final fsrs.Scheduler _scheduler;

  @override
  Future<ReviewRecord> createCard(
    String problemSlug, {
    DateTime? nowUtc,
  }) async {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final card = fsrs.Card(cardId: _stableCardId(problemSlug), due: now);
    return _record(problemSlug, card, const [], now, now);
  }

  @override
  Future<ReviewScheduleResult> rate(
    ReviewRecord record,
    ReviewRating rating, {
    required DateTime reviewedAtUtc,
    int? reviewDurationMs,
  }) async {
    final reviewed = reviewedAtUtc.toUtc();
    final card = fsrs.Card.fromMap(Map<String, dynamic>.from(record.card));
    final scheduled = _scheduler.reviewCard(
      card,
      _rating(rating),
      reviewDateTime: reviewed,
      reviewDuration: reviewDurationMs,
    );
    final event = ReviewEvent(
      id: '${record.id}-${reviewed.microsecondsSinceEpoch}',
      problemSlug: record.problemSlug,
      rating: rating,
      reviewedAtUtc: reviewed,
      dueBeforeUtc: record.nextDueUtc,
      dueAfterUtc: scheduled.card.due.toUtc(),
      fsrsLog: Map<String, Object?>.from(scheduled.reviewLog.toMap()),
      createdAtUtc: reviewed,
    );
    final updated = _record(
      record.problemSlug,
      scheduled.card,
      [...record.logs, event],
      record.createdAtUtc,
      reviewed,
    );
    return ReviewScheduleResult(
      record: updated,
      nextInterval: updated.nextDueUtc.difference(reviewed),
    );
  }

  ReviewRecord _record(
    String slug,
    fsrs.Card card,
    List<ReviewEvent> logs,
    DateTime created,
    DateTime updated,
  ) => ReviewRecord(
    id: 'review-$slug',
    problemSlug: slug,
    card: Map<String, Object?>.from(card.toMap()),
    logs: logs,
    nextDueUtc: card.due.toUtc(),
    lastReviewUtc: card.lastReview?.toUtc(),
    state: card.state.name,
    stability: card.stability,
    difficulty: card.difficulty,
    retrievability: card.lastReview == null
        ? null
        : _scheduler.getCardRetrievability(card, currentDateTime: updated),
    createdAtUtc: created.toUtc(),
    updatedAtUtc: updated.toUtc(),
  );
}

fsrs.Rating _rating(ReviewRating rating) => switch (rating) {
  ReviewRating.again => fsrs.Rating.again,
  ReviewRating.hard => fsrs.Rating.hard,
  ReviewRating.good => fsrs.Rating.good,
  ReviewRating.easy => fsrs.Rating.easy,
};

int _stableCardId(String value) {
  var hash = 0xcbf29ce484222325;
  for (final code in value.codeUnits) {
    hash ^= code;
    hash = (hash * 0x100000001b3) & 0x7fffffffffffffff;
  }
  return hash;
}
