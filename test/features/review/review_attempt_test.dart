import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/review/review_attempt.dart';
import 'package:offline_leetcode_trainer/features/review/review_models.dart';

void main() {
  test('timer pauses and resumes without counting paused time', () {
    final timer = ReviewTimer(startedAtUtc: DateTime.utc(2026, 7, 22, 10));
    timer.pause(DateTime.utc(2026, 7, 22, 10, 5));
    timer.resume(DateTime.utc(2026, 7, 22, 10, 15));

    expect(timer.elapsedAt(DateTime.utc(2026, 7, 22, 10, 20)), 600000);
  });

  test('abandoned attempt closes without an FSRS rating', () {
    final start = DateTime.utc(2026, 7, 22, 10);
    final attempt =
        ReviewAttempt.start(
          id: 'attempt-two-sum-1',
          problemSlug: 'two-sum',
          startedAtUtc: start,
          isFsrsReview: true,
          dueDateBeforeUtc: start,
          platform: 'android',
        ).finish(
          finishedAtUtc: start.add(const Duration(minutes: 5)),
          elapsedMilliseconds: 300000,
          abandoned: true,
        );

    expect(attempt.abandoned, isTrue);
    expect(attempt.fsrsRating, isNull);
    expect(attempt.finishedAtUtc, isNotNull);
  });

  test('attempt telemetry and optional note round trip', () {
    final attempt =
        ReviewAttempt.start(
          id: 'attempt-two-sum-2',
          problemSlug: 'two-sum',
          startedAtUtc: DateTime.utc(2026, 7, 22),
          isFsrsReview: true,
          dueDateBeforeUtc: DateTime.utc(2026, 7, 22),
          platform: 'linux',
        ).copyWith(
          runTestCount: 2,
          submitCount: 1,
          passedTests: 3,
          totalTests: 3,
          hintsUsed: const [1, 2],
          customTestsUsed: 1,
          timeComplexity: 'O(n)',
          spaceComplexity: 'O(n)',
          whatWentWrong: 'Missed the empty case.',
          fsrsRating: ReviewRating.hard,
        );

    expect(ReviewAttempt.fromJson(attempt.toJson()), attempt);
  });
}
