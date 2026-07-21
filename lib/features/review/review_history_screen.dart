import 'package:flutter/material.dart';

import '../../core/design/olt_design.dart';
import 'review_attempt.dart';
import 'review_models.dart';

class ReviewHistoryScreen extends StatefulWidget {
  const ReviewHistoryScreen({
    required this.problemSlug,
    required this.attempts,
    super.key,
  });

  final String problemSlug;
  final List<ReviewAttempt> attempts;

  @override
  State<ReviewHistoryScreen> createState() => _ReviewHistoryScreenState();
}

class _ReviewHistoryScreenState extends State<ReviewHistoryScreen> {
  String filter = 'all';

  @override
  Widget build(BuildContext context) {
    final values = widget.attempts.where(_matches).toList()
      ..sort((a, b) => b.startedAtUtc.compareTo(a.startedAtUtc));
    return Scaffold(
      appBar: AppBar(
        title: Text('HISTORY/${widget.problemSlug.toUpperCase()}'),
      ),
      body: OltPanel(
        label: 'ATTEMPTS/${values.length} · STORAGE/LOCAL',
        child: ListView(
          padding: const EdgeInsets.all(OltSpace.x3),
          children: [
            Wrap(
              spacing: OltSpace.x2,
              runSpacing: OltSpace.x2,
              children: [
                for (final value in const [
                  'all',
                  'successful',
                  'failed',
                  'again',
                  'hard',
                  'good',
                  'easy',
                ])
                  OltButton(
                    label: value.toUpperCase(),
                    signal: filter == value,
                    onPressed: () => setState(() => filter = value),
                  ),
              ],
            ),
            const SizedBox(height: OltSpace.x3),
            if (values.isEmpty) const Text('NO MATCHING ATTEMPTS'),
            for (final attempt in values)
              Container(
                margin: const EdgeInsets.only(bottom: OltSpace.x2),
                padding: const EdgeInsets.all(OltSpace.x3),
                decoration: const BoxDecoration(
                  color: OltColors.raised,
                  border: Border.fromBorderSide(
                    BorderSide(color: OltColors.border),
                  ),
                ),
                child: Text(
                  '${attempt.startedAtUtc.toLocal()} · '
                  '${attempt.successful
                      ? 'SUCCESS'
                      : attempt.abandoned
                      ? 'ABANDONED'
                      : 'FAILED'} · '
                  '${attempt.fsrsRating?.name.toUpperCase() ?? 'UNRATED'}\n'
                  'RUNS ${attempt.runTestCount} · SUBMITS ${attempt.submitCount} · '
                  'HINTS ${attempt.hintsUsed.join(', ')}',
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _matches(ReviewAttempt attempt) => switch (filter) {
    'successful' => attempt.successful,
    'failed' => !attempt.successful,
    'again' => attempt.fsrsRating == ReviewRating.again,
    'hard' => attempt.fsrsRating == ReviewRating.hard,
    'good' => attempt.fsrsRating == ReviewRating.good,
    'easy' => attempt.fsrsRating == ReviewRating.easy,
    _ => true,
  };
}
