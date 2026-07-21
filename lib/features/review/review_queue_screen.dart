import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../core/design/olt_design.dart';
import 'review_history_screen.dart';
import 'review_repository.dart';

class ReviewQueueScreen extends StatelessWidget {
  const ReviewQueueScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final queue = controller.reviewQueue;
      final due = queue
          .where((item) => item.bucket != ReviewQueueBucket.upcoming)
          .toList();
      final estimate = due.fold<int>(0, (total, item) {
        final problem = controller.problems.firstWhere(
          (value) => value.slug == item.record.problemSlug,
        );
        return total + controller.reviewTargetMinutes(problem.difficulty);
      });
      return Scaffold(
        appBar: AppBar(
          title: const Text('REVIEW QUEUE'),
          leading: Navigator.canPop(context) ? const BackButton() : null,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(OltSpace.x2),
            child: OltPanel(
              label: 'FSRS/2.0.1 · RETENTION/0.90 · DATA/LOCAL',
              child: ListView(
                padding: const EdgeInsets.all(OltSpace.x3),
                children: [
                  Wrap(
                    spacing: OltSpace.x2,
                    runSpacing: OltSpace.x2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${due.length} DUE',
                        key: const Key('review-due-count'),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: OltColors.signal),
                      ),
                      Text('ESTIMATED $estimate MIN', style: microStyle),
                      OltButton(
                        label: 'START NEXT',
                        signal: true,
                        onPressed: due.isEmpty
                            ? null
                            : () =>
                                  _start(context, due.first.record.problemSlug),
                      ),
                      OltButton(
                        label: 'SETTINGS',
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) =>
                              _ReviewSettingsDialog(controller: controller),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: OltSpace.x4),
                  for (final bucket in ReviewQueueBucket.values) ...[
                    Text(_label(bucket), style: microStyle),
                    const SizedBox(height: OltSpace.x2),
                    for (final item in queue.where(
                      (value) => value.bucket == bucket,
                    ))
                      _ReviewCard(
                        title: controller.problems
                            .firstWhere(
                              (value) => value.slug == item.record.problemSlug,
                            )
                            .title,
                        due: item.record.nextDueUtc.toLocal(),
                        onStart: () => _start(context, item.record.problemSlug),
                        onPostpone: () =>
                            controller.postponeReview(item.record),
                        onHistory: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReviewHistoryScreen(
                              problemSlug: item.record.problemSlug,
                              attempts: controller.state.reviewAttempts.values
                                  .where(
                                    (attempt) =>
                                        attempt.problemSlug ==
                                        item.record.problemSlug,
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: OltSpace.x3),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Future<void> _start(BuildContext context, String slug) async {
    final problem = controller.problems.firstWhere(
      (value) => value.slug == slug,
    );
    await controller.startReview(problem);
    if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);
  }

  String _label(ReviewQueueBucket value) => switch (value) {
    ReviewQueueBucket.overdue => 'OVERDUE',
    ReviewQueueBucket.due => 'DUE TODAY',
    ReviewQueueBucket.newCard => 'NEW REVIEW CARDS',
    ReviewQueueBucket.upcoming => 'UPCOMING',
  };
}

class _ReviewSettingsDialog extends StatefulWidget {
  const _ReviewSettingsDialog({required this.controller});

  final AppController controller;

  @override
  State<_ReviewSettingsDialog> createState() => _ReviewSettingsDialogState();
}

class _ReviewSettingsDialogState extends State<_ReviewSettingsDialog> {
  late final retention = TextEditingController(
    text: '${widget.controller.state.settings['desiredRetention'] ?? 0.90}',
  );
  late final easy = TextEditingController(
    text: '${widget.controller.reviewTargetMinutes('easy')}',
  );
  late final medium = TextEditingController(
    text: '${widget.controller.reviewTargetMinutes('medium')}',
  );
  late final hard = TextEditingController(
    text: '${widget.controller.reviewTargetMinutes('hard')}',
  );
  String? error;

  @override
  void dispose() {
    retention.dispose();
    easy.dispose();
    medium.dispose();
    hard.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('REVIEW SETTINGS'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('retention-field'),
            controller: retention,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Desired retention (0.70–0.99)',
              helperText: 'Higher retention schedules reviews more often.',
            ),
          ),
          TextField(
            controller: easy,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Easy target minutes'),
          ),
          TextField(
            controller: medium,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Medium target minutes',
            ),
          ),
          TextField(
            controller: hard,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Hard target minutes'),
          ),
          if (error != null)
            Text(error!, style: const TextStyle(color: OltColors.danger)),
        ],
      ),
    ),
    actions: [
      OltButton(label: 'CANCEL', onPressed: () => Navigator.pop(context)),
      OltButton(
        label: 'SAVE',
        signal: true,
        onPressed: () {
          try {
            widget.controller.updateReviewSettings(
              desiredRetention: double.parse(retention.text),
              easyMinutes: int.parse(easy.text),
              mediumMinutes: int.parse(medium.text),
              hardMinutes: int.parse(hard.text),
            );
            Navigator.pop(context);
          } on Object {
            setState(
              () => error = 'Enter retention 0.70–0.99 and targets 1–240.',
            );
          }
        },
      ),
    ],
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.due,
    required this.onStart,
    required this.onPostpone,
    required this.onHistory,
  });

  final String title;
  final DateTime due;
  final VoidCallback onStart;
  final VoidCallback onPostpone;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: OltSpace.x2),
    padding: const EdgeInsets.all(OltSpace.x3),
    decoration: const BoxDecoration(
      color: OltColors.raised,
      border: Border.fromBorderSide(BorderSide(color: OltColors.border)),
    ),
    child: Wrap(
      spacing: OltSpace.x2,
      runSpacing: OltSpace.x2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 220,
          child: Text('$title\nDUE ${due.toString().substring(0, 16)}'),
        ),
        OltButton(label: 'START', signal: true, onPressed: onStart),
        OltButton(label: 'REVIEW EARLY', onPressed: onStart),
        OltButton(label: 'POSTPONE 1D', onPressed: onPostpone),
        OltButton(label: 'HISTORY', onPressed: onHistory),
      ],
    ),
  );
}
