import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../core/design/olt_design.dart';
import 'review_models.dart';

class ReviewSummarySheet extends StatelessWidget {
  const ReviewSummarySheet({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final attempt = controller.activeReviewAttempt;
    if (attempt == null) {
      return const Center(child: Text('NO ACTIVE REVIEW'));
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(OltSpace.x3),
        child: OltPanel(
          label: 'REVIEW SUMMARY',
          child: FutureBuilder<Map<ReviewRating, Duration>>(
            future: controller.previewReviewIntervals(),
            builder: (context, snapshot) => ListView(
              padding: const EdgeInsets.all(OltSpace.x3),
              children: [
                Text(
                  'REVIEW SUMMARY',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: OltSpace.x3),
                Text(
                  'SOLVE TIME ${_duration(Duration(milliseconds: controller.activeReviewElapsedMilliseconds))}\n'
                  'RESULT ${attempt.successful ? 'SUCCESSFUL' : 'UNSUCCESSFUL'}\n'
                  'OFFICIAL RUNS ${attempt.runTestCount} · SUBMITS ${attempt.submitCount}\n'
                  'CUSTOM TESTS ${attempt.customTestsUsed} · HINTS ${attempt.hintsUsed.join(', ')}\n'
                  'FINAL ${attempt.finalSubmissionResult ?? 'NOT SUBMITTED'}\n'
                  'PREVIOUS INTERVAL ${_previousInterval(controller).toUpperCase()}\n'
                  'TIME ${attempt.timeComplexity ?? 'NOT ENTERED'} · SPACE ${attempt.spaceComplexity ?? 'NOT ENTERED'}',
                ),
                const SizedBox(height: OltSpace.x4),
                const Text(
                  'Choose your rating. Time and hints are context only; the app never rates for you.',
                ),
                const SizedBox(height: OltSpace.x3),
                Wrap(
                  spacing: OltSpace.x2,
                  runSpacing: OltSpace.x2,
                  children: [
                    for (final rating in ReviewRating.values)
                      OltButton(
                        label:
                            '${_title(rating)} · NEXT ${_duration(snapshot.data?[rating])}',
                        signal: rating == ReviewRating.good,
                        onPressed: snapshot.hasData
                            ? () async {
                                await controller.rateActiveReview(rating);
                                if (context.mounted &&
                                    Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }
                              }
                            : null,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _previousInterval(AppController controller) {
  final attempt = controller.activeReviewAttempt;
  final record = attempt == null
      ? null
      : controller.state.reviewRecords[attempt.problemSlug];
  if (record == null || record.logs.isEmpty) return 'new';
  final last = record.logs.last;
  return _duration(last.dueAfterUtc.difference(last.reviewedAtUtc));
}

String _title(ReviewRating value) => switch (value) {
  ReviewRating.again => 'Again',
  ReviewRating.hard => 'Hard',
  ReviewRating.good => 'Good',
  ReviewRating.easy => 'Easy',
};

String _duration(Duration? value) {
  if (value == null) return '…';
  if (value.inDays > 0) return '${value.inDays}D';
  if (value.inHours > 0) return '${value.inHours}H';
  return '${value.inMinutes}M';
}
