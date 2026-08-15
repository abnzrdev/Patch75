import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/app/app_controller.dart';
import 'package:offline_leetcode_trainer/core/storage/app_state.dart';
import 'package:offline_leetcode_trainer/core/design/olt_design.dart';
import 'package:offline_leetcode_trainer/features/problems/problem.dart';
import 'package:offline_leetcode_trainer/features/review/fsrs_scheduler_service.dart';
import 'package:offline_leetcode_trainer/features/review/review_queue_screen.dart';
import 'package:offline_leetcode_trainer/features/review/review_summary_sheet.dart';

void main() {
  testWidgets('review queue shows due badge, estimate, and start actions', (
    tester,
  ) async {
    final controller = await _controllerWithCard();

    await tester.pumpWidget(
      MaterialApp(home: ReviewQueueScreen(controller: controller)),
    );

    expect(find.text('REVIEW QUEUE'), findsOneWidget);
    expect(find.byKey(const Key('review-due-count')), findsOneWidget);
    expect(find.textContaining('ESTIMATED'), findsOneWidget);
    expect(find.text('START NEXT'), findsOneWidget);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('timed review summary requires an explicit rating', (
    tester,
  ) async {
    final controller = await _controllerWithCard(start: true);

    await tester.pumpWidget(
      MaterialApp(home: ReviewSummarySheet(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('REVIEW SUMMARY'), findsNWidgets(2));
    await tester.fling(find.byType(ListView), const Offset(0, -600), 1200);
    await tester.pumpAndSettle();
    for (final label in ['Again', 'Hard', 'Good', 'Easy']) {
      expect(
        find.byWidgetPredicate(
          (widget) => widget is OltButton && widget.label.startsWith(label),
        ),
        findsOneWidget,
      );
    }
    controller.dispose();
  });

  testWidgets('review queue fits Android portrait without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = await _controllerWithCard();

    await tester.pumpWidget(
      MaterialApp(home: ReviewQueueScreen(controller: controller)),
    );

    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('review settings expose retention and time targets', (
    tester,
  ) async {
    final controller = await _controllerWithCard();
    await tester.pumpWidget(
      MaterialApp(home: ReviewQueueScreen(controller: controller)),
    );

    await tester.tap(find.text('SETTINGS'));
    await tester.pumpAndSettle();

    expect(find.text('REVIEW SETTINGS'), findsOneWidget);
    expect(find.byKey(const Key('retention-field')), findsOneWidget);
    expect(find.text('Easy target minutes'), findsOneWidget);
    expect(find.text('Medium target minutes'), findsOneWidget);
    expect(find.text('Hard target minutes'), findsOneWidget);
    controller.dispose();
  });
}

Future<AppController> _controllerWithCard({bool start = false}) async {
  final problem = Problem.fromJson(
    jsonDecode(_problemJson) as Map<String, Object?>,
  );
  final controller = AppController(
    problem: problem,
    state: const AppState(progress: {'two-sum': 'solved'}),
    reviewScheduler: FsrsSchedulerService(),
    now: () => DateTime.utc(2026, 7, 22, 12),
  );
  await controller.initializeReviews();
  if (start) await controller.startReview(problem);
  return controller;
}

const _problemJson = r'''
{"id":1,"slug":"two-sum","title":"Two Sum","difficulty":"easy","topics":["array"],"description":"Return the increasing pair of matching indices.","examples":[],"constraints":[],"starterCodeByLanguage":{"python":"class Solution: pass"},"testCases":[],"source":"Patch75","sourceUrl":"","license":"AGPL-3.0-only","originalContent":true}
''';
