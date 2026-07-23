import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/app/app_controller.dart';
import 'package:offline_leetcode_trainer/app/offline_trainer_app.dart';
import 'package:offline_leetcode_trainer/core/storage/app_state.dart';
import 'package:offline_leetcode_trainer/features/judge/judge_models.dart';
import 'package:offline_leetcode_trainer/features/judge/judge_service.dart';
import 'package:offline_leetcode_trainer/features/problems/problem.dart';
import 'package:offline_leetcode_trainer/features/workspace/python_code_theme.dart';
import 'package:re_editor/re_editor.dart';

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

    expect(find.text('PATCH75'), findsOneWidget);
    expect(find.textContaining('PROBLEM/0001'), findsOneWidget);
    expect(
      tester
          .widgetList<RichText>(find.byType(RichText))
          .any(
            (widget) => widget.text.toPlainText().contains(
              'Given an array of integers',
            ),
          ),
      isTrue,
    );
    expect(find.byKey(const Key('problem-pane')), findsOneWidget);
    expect(find.byKey(const Key('editor-pane')), findsOneWidget);
    expect(find.byKey(const Key('right-pane')), findsOneWidget);
    expect(find.text('NO LOCAL MATERIALS'), findsOneWidget);
    await _disposeEditor(tester);
  });

  testWidgets('runs scratch code and supports copy and clear output', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = AppController(
      problem: problem,
      state: const AppState(),
      judgeService: _ScratchJudge(),
    )..judgeAvailable = true;
    String? clipboard;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(OfflineTrainerApp(controller: controller));
    await tester.tap(find.text('CODE'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('run-code')));
    await tester.pumpAndSettle();

    expect(find.text('RUN/PASSED · TIME/6MS'), findsOneWidget);
    expect(find.text('hello\n'), findsOneWidget);
    await tester.tap(find.byKey(const Key('copy-output')));
    await tester.pump();
    expect(clipboard, 'hello\nwarning');

    await tester.tap(find.byKey(const Key('clear-output')));
    await tester.pump();
    expect(controller.judgeResult, isNull);
    expect(find.byKey(const Key('copy-output')), findsNothing);
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
    expect(find.text('MATERIALS'), findsOneWidget);
    expect(find.text('NOTES'), findsOneWidget);

    await tester.tap(find.text('CODE'));
    await tester.pump();
    expect(find.byKey(const Key('editor-pane')), findsOneWidget);
    await _disposeEditor(tester);
  });

  testWidgets('large text scale remains usable at a narrow width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 780);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      OfflineTrainerApp(
        controller: AppController(problem: problem, state: const AppState()),
      ),
    );

    expect(find.text('PROBLEM'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeEditor(tester);
  });

  testWidgets('editor and notes fill from the top-left', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      OfflineTrainerApp(
        controller: AppController(problem: problem, state: const AppState()),
      ),
    );

    final editor = tester.widget<CodeEditor>(
      find.byKey(const Key('code-editor')),
    );
    expect(editor.style!.codeTheme, pythonCodeTheme);
    expect(editor.padding, const EdgeInsets.all(12));

    final notes = tester.widget<TextField>(
      find.byKey(const Key('notes-field')),
    );
    expect(notes.textAlignVertical, TextAlignVertical.top);
    expect(notes.expands, isTrue);
    expect(find.text('0 CHARACTERS'), findsOneWidget);
    final notesTop = tester.getTopLeft(find.byKey(const Key('notes-field'))).dy;
    final editableTop = tester
        .getTopLeft(
          find.descendant(
            of: find.byKey(const Key('notes-field')),
            matching: find.byType(EditableText),
          ),
        )
        .dy;
    expect(editableTop - notesTop, lessThan(24));
    await _disposeEditor(tester);
  });

  testWidgets('long problem descriptions scroll through constraints', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final longProblem = Problem.fromJson({
      ...(jsonDecode(_twoSumJson) as Map<String, Object?>),
      'description': List.filled(
        20,
        'Readable paragraph with `inline_code`.',
      ).join('\n\n'),
      'constraints': ['first constraint', 'FINAL CONSTRAINT'],
    });
    await tester.pumpWidget(
      OfflineTrainerApp(
        controller: AppController(
          problem: longProblem,
          state: const AppState(),
        ),
      ),
    );

    expect(find.byKey(const Key('problem-description')), findsOneWidget);
    for (var i = 0; i < 8; i++) {
      await tester.drag(
        find.byKey(const Key('problem-scroll')),
        const Offset(0, -500),
      );
      await tester.pump();
    }
    expect(find.byKey(const Key('constraint-list')), findsOneWidget);
    expect(
      tester
          .widgetList<RichText>(find.byType(RichText))
          .any(
            (widget) => widget.text.toPlainText().contains('FINAL CONSTRAINT'),
          ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await _disposeEditor(tester);
  });

  testWidgets('Android landscape layout has no overflow', (tester) async {
    tester.view.physicalSize = const Size(1000, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      OfflineTrainerApp(
        controller: AppController(problem: problem, state: const AppState()),
      ),
    );

    expect(find.byKey(const Key('problem-pane')), findsOneWidget);
    await tester.tap(find.text('MATERIALS'));
    await tester.pump();
    expect(find.byKey(const Key('materials-scroll')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeEditor(tester);
  });

  testWidgets('lifecycle pause stops and resume restarts the timer', (
    tester,
  ) async {
    final controller = AppController(problem: problem, state: const AppState());
    await tester.pumpWidget(OfflineTrainerApp(controller: controller));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(controller.timerPaused, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(controller.timerPaused, isFalse);
    await _disposeEditor(tester);
  });
}

Future<void> _disposeEditor(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpWidget(const SizedBox());
}

class _ScratchJudge implements JudgeService {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<JudgeResult> run(
    JudgeRequest request,
    List<JudgeTestInput> tests,
  ) async => const JudgeResult(
    status: JudgeStatus.passed,
    stdout: 'hello\n',
    stderr: 'warning',
    executionTimeMs: 6,
    memoryUsageBytes: null,
    passedTests: 0,
    totalTests: 0,
    testResults: [],
  );
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
