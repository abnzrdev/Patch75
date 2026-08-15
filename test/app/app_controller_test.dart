import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/app/app_controller.dart';
import 'package:offline_leetcode_trainer/core/storage/app_state.dart';
import 'package:offline_leetcode_trainer/features/judge/judge_models.dart';
import 'package:offline_leetcode_trainer/features/judge/judge_service.dart';
import 'package:offline_leetcode_trainer/features/materials/learning_material.dart';
import 'package:offline_leetcode_trainer/features/materials/local_material_store.dart';
import 'package:offline_leetcode_trainer/features/problems/problem.dart';
import 'package:offline_leetcode_trainer/features/review/fsrs_scheduler_service.dart';
import 'package:offline_leetcode_trainer/features/review/review_models.dart';

void main() {
  test('runs sample tests and exposes the structured result', () async {
    final controller = AppController(
      problem: Problem.fromJson(
        jsonDecode(_problemJson) as Map<String, Object?>,
      ),
      state: const AppState(),
      judgeService: _PassingJudge(),
    );
    addTearDown(controller.dispose);

    await controller.runTests(submit: false);

    expect(controller.judgeResult?.status, JudgeStatus.passed);
    expect(controller.judgeResult?.passedTests, 1);
    expect(controller.judging, isFalse);
    expect(controller.state.testHistory['two-sum'], ['passed:1/1']);
  });

  test('runs scratch code without changing learning state', () async {
    final judge = _CapturingJudge();
    final controller = AppController(
      problem: Problem.fromJson(
        jsonDecode(_problemJson) as Map<String, Object?>,
      ),
      state: const AppState(),
      judgeService: judge,
    );
    addTearDown(controller.dispose);

    await controller.runCode();

    expect(judge.lastRequest?.mode, JudgeMode.scratch);
    expect(controller.judgeResult?.stdout, 'hello\n');
    expect(controller.state.testHistory, isEmpty);
    expect(controller.state.progress, isEmpty);
    expect(controller.state.reviewAttempts, isEmpty);
  });

  test('discards scratch output after navigating to another problem', () async {
    final first = Problem.fromJson(
      jsonDecode(_problemJson) as Map<String, Object?>,
    );
    final second = Problem.fromJson(
      jsonDecode(_problemJson.replaceAll('two-sum', 'three-sum'))
          as Map<String, Object?>,
    );
    final judge = _DelayedJudge();
    final controller = AppController(
      problem: first,
      problems: [first, second],
      state: const AppState(),
      judgeService: judge,
    );
    addTearDown(controller.dispose);

    final running = controller.runCode();
    controller.selectProblem(second);
    judge.complete();
    await running;

    expect(controller.problem, second);
    expect(controller.judgeResult, isNull);
    expect(controller.judging, isFalse);
  });

  test('discards test results after navigating to another problem', () async {
    final first = Problem.fromJson(
      jsonDecode(_problemJson) as Map<String, Object?>,
    );
    final second = Problem.fromJson(
      jsonDecode(_problemJson.replaceAll('two-sum', 'three-sum'))
          as Map<String, Object?>,
    );
    final judge = _DelayedJudge();
    final controller = AppController(
      problem: first,
      problems: [first, second],
      state: const AppState(),
      judgeService: judge,
    );
    addTearDown(controller.dispose);

    final running = controller.runTests(submit: true);
    controller.selectProblem(second);
    judge.complete();
    await running;

    expect(controller.problem, second);
    expect(controller.judgeResult, isNull);
    expect(controller.state.testHistory, isEmpty);
    expect(controller.state.reviewRecords, isEmpty);
    expect(controller.judging, isFalse);
  });

  test(
    'flush waits for pending saves and exposes persistence failures',
    () async {
      final save = Completer<void>();
      final controller = AppController(
        problem: Problem.fromJson(
          jsonDecode(_problemJson) as Map<String, Object?>,
        ),
        state: const AppState(),
        onSave: (_) => save.future,
      );
      addTearDown(controller.dispose);

      controller.updateDraft('changed');
      final flushing = controller.flush();
      var finished = false;
      flushing.then((_) => finished = true);
      await Future<void>.delayed(Duration.zero);
      expect(finished, isFalse);
      save.completeError(StateError('disk full'));
      await flushing;

      expect(controller.persistenceError, contains('disk full'));
    },
  );

  test('imports materials per problem', () async {
    final root = await Directory.systemTemp.createTemp('olt-controller-');
    addTearDown(() => root.delete(recursive: true));
    final picks = <PlatformFile>[
      PlatformFile(
        name: 'notes.txt',
        size: 4,
        bytes: Uint8List.fromList([4, 5, 6, 7]),
      ),
    ];
    final problems = [
      Problem.fromJson(jsonDecode(_problemJson) as Map<String, Object?>),
      Problem.fromJson(
        jsonDecode(_problemJson.replaceAll('two-sum', 'three-sum'))
            as Map<String, Object?>,
      ),
    ];
    final controller = AppController(
      problem: problems.first,
      problems: problems,
      state: const AppState(),
      materialStore: LocalMaterialStore(
        supportDirectory: Directory('${root.path}/support'),
        picker: (_) async => picks.removeAt(0),
      ),
    );
    addTearDown(controller.dispose);

    expect(controller.materials, isEmpty);
    await controller.addMaterial();
    expect(controller.materials.single.name, 'notes.txt');

    controller.selectProblem(problems.last);
    expect(controller.materials, isEmpty);
  });

  test('replaces, opens and removes a material after saving state', () async {
    final root = await Directory.systemTemp.createTemp('olt-controller-');
    addTearDown(() => root.delete(recursive: true));
    final support = Directory('${root.path}/support');
    final store = LocalMaterialStore(
      supportDirectory: support,
      picker: (_) async => PlatformFile(
        name: 'replacement.md',
        size: 3,
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
    );
    final oldFile = File('${support.path}/materials/two-sum/material-old.txt');
    await oldFile.parent.create(recursive: true);
    await oldFile.writeAsString('old');
    final old = LearningMaterial(
      id: 'old',
      name: 'old.txt',
      path: oldFile.path,
      kind: LearningMaterialKind.text,
      extension: 'txt',
      sizeBytes: 3,
    );
    final events = <String>[];
    final controller = AppController(
      problem: Problem.fromJson(
        jsonDecode(_problemJson) as Map<String, Object?>,
      ),
      state: AppState(
        materials: {
          'two-sum': [old],
        },
      ),
      materialStore: store,
      materialOpener: (material) async {
        events.add('open:${material.name}');
        return null;
      },
      onSave: (state) async {
        final values = state.materials['two-sum'] ?? const [];
        events.add('save:${values.isEmpty ? 'empty' : values.single.name}');
      },
    );
    addTearDown(controller.dispose);

    await controller.replaceMaterial(old);
    final replacement = controller.materials.single;
    expect(events.first, 'save:replacement.md');
    expect(await oldFile.exists(), isFalse);

    await controller.openMaterial(replacement);
    expect(events, contains('open:replacement.md'));

    await controller.removeMaterial(replacement);
    expect(events, contains('save:empty'));
    expect(await File(replacement.path).exists(), isFalse);
  });

  test('keeps notes separate when navigating between problems', () {
    final first = Problem.fromJson(
      jsonDecode(_problemJson) as Map<String, Object?>,
    );
    final second = Problem.fromJson(
      jsonDecode(_problemJson.replaceAll('two-sum', 'three-sum'))
          as Map<String, Object?>,
    );
    final controller = AppController(
      problem: first,
      problems: [first, second],
      state: const AppState(notes: {'two-sum': 'map note'}),
    );
    addTearDown(controller.dispose);

    expect(controller.notes, 'map note');
    controller.selectProblem(second);
    controller.updateNotes('pointer note');
    controller.selectProblem(first);
    expect(controller.notes, 'map note');
    expect(controller.state.notes['three-sum'], 'pointer note');
  });

  test(
    'migrates solved progress and prevents duplicate review cards',
    () async {
      final problem = Problem.fromJson(
        jsonDecode(_problemJson) as Map<String, Object?>,
      );
      final controller = AppController(
        problem: problem,
        state: const AppState(progress: {'two-sum': 'solved'}),
        reviewScheduler: FsrsSchedulerService(),
        now: () => DateTime.utc(2026, 7, 22),
      );
      addTearDown(controller.dispose);

      await controller.initializeReviews();
      await controller.initializeReviews();

      expect(controller.state.reviewRecords, hasLength(1));
      expect(controller.dueReviewCount, 1);
    },
  );

  test(
    'successful submission creates a card and records attempt telemetry',
    () async {
      final problem = Problem.fromJson(
        jsonDecode(_problemJson) as Map<String, Object?>,
      );
      var now = DateTime.utc(2026, 7, 22, 10);
      final controller = AppController(
        problem: problem,
        state: const AppState(),
        judgeService: _PassingJudge(),
        reviewScheduler: FsrsSchedulerService(),
        now: () => now,
        platformName: 'test',
      );
      addTearDown(controller.dispose);

      await controller.startReview(problem);
      await controller.runTests(submit: false);
      now = now.add(const Duration(minutes: 3));
      await controller.runTests(submit: true);

      expect(controller.state.reviewRecords['two-sum'], isNotNull);
      expect(controller.activeReviewAttempt?.runTestCount, 1);
      expect(controller.activeReviewAttempt?.submitCount, 1);
      expect(controller.activeReviewAttempt?.successful, isTrue);

      await controller.rateActiveReview(ReviewRating.good);
      expect(controller.activeReviewAttempt, isNull);
      expect(
        controller.state.reviewAttempts.values.single.fsrsRating,
        ReviewRating.good,
      );
    },
  );

  test('abandoning a review persists history without rating', () async {
    final problem = Problem.fromJson(
      jsonDecode(_problemJson) as Map<String, Object?>,
    );
    final controller = AppController(
      problem: problem,
      state: const AppState(),
      reviewScheduler: FsrsSchedulerService(),
      now: () => DateTime.utc(2026, 7, 22),
    );
    addTearDown(controller.dispose);

    await controller.startReview(problem);
    controller.abandonReview();

    expect(controller.state.reviewAttempts.values.single.abandoned, isTrue);
    expect(controller.state.reviewAttempts.values.single.fsrsRating, isNull);
  });

  test('reveals hints in order and records review telemetry', () async {
    final problem =
        Problem.fromJson(
          jsonDecode(_problemJson) as Map<String, Object?>,
        ).withLearningMetadata(const {
          'hints': ['nudge', 'idea', 'pseudocode'],
          'time': 'O(n)',
          'space': 'O(n)',
          'explanation': 'map',
        });
    final controller = AppController(
      problem: problem,
      state: const AppState(),
      now: () => DateTime.utc(2026, 7, 22),
    );
    addTearDown(controller.dispose);
    await controller.startReview(problem);

    controller.revealNextHint();
    controller.revealNextHint();
    controller.revealNextHint();
    controller.revealNextHint();

    expect(controller.revealedHintLevels, [1, 2, 3]);
    expect(controller.activeReviewAttempt?.hintsUsed, [1, 2, 3]);
  });

  test('custom results remain separate and never mark solved', () async {
    final judge = _CapturingJudge();
    final problem = Problem.fromJson(
      jsonDecode(_problemJson) as Map<String, Object?>,
    );
    final controller = AppController(
      problem: problem,
      state: const AppState(),
      judgeService: judge,
      now: () => DateTime.utc(2026, 7, 22),
    );
    addTearDown(controller.dispose);
    controller.saveCustomTest(
      name: 'custom',
      input: const {
        'nums': [8, 6],
        'target': 14,
      },
    );

    await controller.runCustomTests();

    expect(judge.lastRequest?.submit, isFalse);
    expect(controller.customJudgeResult?.status, JudgeStatus.passed);
    expect(controller.judgeResult, isNull);
    expect(controller.state.progress['two-sum'], isNot('solved'));
  });
}

class _PassingJudge implements JudgeService {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<JudgeResult> run(
    JudgeRequest request,
    List<JudgeTestInput> tests,
  ) async => JudgeResult(
    status: JudgeStatus.passed,
    stdout: request.mode == JudgeMode.scratch ? 'hello\n' : '',
    stderr: '',
    executionTimeMs: 4,
    memoryUsageBytes: null,
    passedTests: tests.length,
    totalTests: tests.length,
    testResults: [
      for (final test in tests)
        JudgeTestResult(
          id: test.id,
          passed: true,
          output: '[0,1]',
          expected: '[0,1]',
          error: null,
        ),
    ],
  );
}

class _CapturingJudge extends _PassingJudge {
  JudgeRequest? lastRequest;

  @override
  Future<JudgeResult> run(JudgeRequest request, List<JudgeTestInput> tests) {
    lastRequest = request;
    return super.run(request, tests);
  }
}

class _DelayedJudge extends _PassingJudge {
  final _result = Completer<JudgeResult>();

  void complete() => _result.complete(
    const JudgeResult(
      status: JudgeStatus.passed,
      stdout: 'stale',
      stderr: '',
      executionTimeMs: 1,
      memoryUsageBytes: null,
      passedTests: 0,
      totalTests: 0,
      testResults: [],
    ),
  );

  @override
  Future<JudgeResult> run(JudgeRequest request, List<JudgeTestInput> tests) =>
      _result.future;
}

const _problemJson = r'''
{
  "id": 1,
  "slug": "two-sum",
  "title": "Two Sum",
  "difficulty": "easy",
  "topics": ["array"],
  "description": "Return the increasing pair of matching indices.",
  "examples": [],
  "constraints": [],
  "starterCodeByLanguage": {"python":"class Solution: pass"},
  "testCases": [{"id":"sample-1","input":{"nums":[8,6],"target":14},"expected":[0,1],"sample":true}],
  "source":"Patch75","sourceUrl":"","license":"AGPL-3.0-only","originalContent":true
}
''';
