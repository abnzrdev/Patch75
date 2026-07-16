import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/app/app_controller.dart';
import 'package:offline_leetcode_trainer/app/offline_trainer_app.dart';
import 'package:offline_leetcode_trainer/core/storage/app_state.dart';
import 'package:offline_leetcode_trainer/features/problems/problem.dart';

void main() {
  late Problem problem;

  setUp(() {
    problem = Problem.fromJson(jsonDecode(_twoSumJson) as Map<String, Object?>);
  });

  testWidgets('desktop shows the complete Two Sum workspace', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      OfflineTrainerApp(
        controller: AppController(problem: problem, state: const AppState()),
      ),
    );

    expect(find.text('OFFLINE LEETCODE TRAINER'), findsOneWidget);
    expect(find.textContaining('PROBLEM/0001'), findsOneWidget);
    expect(find.text('Given an array of integers'), findsOneWidget);
    expect(find.byKey(const Key('problem-pane')), findsOneWidget);
    expect(find.byKey(const Key('editor-pane')), findsOneWidget);
    expect(find.byKey(const Key('right-pane')), findsOneWidget);
    expect(find.text('ANIM/LOCAL-ASSET-MISSING'), findsOneWidget);
    await _disposeEditor(tester);
  });

  testWidgets('focus mode expands work area and has an obvious exit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      OfflineTrainerApp(
        controller: AppController(problem: problem, state: const AppState()),
      ),
    );

    await tester.tap(find.byKey(const Key('focus-toggle')));
    await tester.pump();

    expect(find.byKey(const Key('right-pane')), findsNothing);
    expect(find.text('EXIT FOCUS'), findsOneWidget);
    await _disposeEditor(tester);
  });

  testWidgets('compact layout uses five destinations instead of columns', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      OfflineTrainerApp(
        controller: AppController(problem: problem, state: const AppState()),
      ),
    );

    expect(find.byKey(const Key('problem-pane')), findsOneWidget);
    expect(find.byKey(const Key('editor-pane')), findsNothing);
    expect(find.text('PROBLEM'), findsOneWidget);
    expect(find.text('CODE'), findsOneWidget);
    expect(find.text('RESULTS'), findsOneWidget);
    expect(find.text('ANIMATION'), findsOneWidget);
    expect(find.text('NOTES'), findsOneWidget);

    await tester.tap(find.text('CODE'));
    await tester.pump();
    expect(find.byKey(const Key('editor-pane')), findsOneWidget);
    await _disposeEditor(tester);
  });
}

Future<void> _disposeEditor(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpWidget(const SizedBox());
}

const _twoSumJson = r'''
{
  "id": 1,
  "slug": "two-sum",
  "title": "Two Sum",
  "difficulty": "easy",
  "topics": ["array", "hash-table"],
  "description": "Given an array of integers",
  "examples": [{"input":"nums = [2,7], target = 9","output":"[0,1]"}],
  "constraints": ["2 <= nums.length <= 10^4"],
  "starterCodeByLanguage": {"python":"class Solution:\n    pass"},
  "testCases": [{"id":"sample-1","input":{"nums":[2,7],"target":9},"expected":[0,1],"sample":true}],
  "source": "cojudge",
  "sourceUrl": "https://github.com/cojudge/cojudge"
}
''';
