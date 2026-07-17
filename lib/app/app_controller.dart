import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/storage/app_state.dart';
import '../features/animations/local_animation_store.dart';
import '../features/judge/judge_models.dart';
import '../features/judge/judge_service.dart';
import '../features/problems/problem.dart';

class AppController extends ChangeNotifier {
  AppController({
    required Problem problem,
    List<Problem>? problems,
    required this.state,
    this.onSave,
    this.animationStore,
    JudgeService? judgeService,
  }) : problem = problem,
       problems = problems ?? [problem],
       judgeService = judgeService ?? const UnsupportedJudgeService() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_timerPaused) {
        final timers = {...state.timerSeconds};
        timers[problem.slug] = elapsedSeconds + 1;
        state = state.copyWith(timerSeconds: timers);
        notifyListeners();
      }
    });
  }

  Problem problem;
  final List<Problem> problems;
  final Future<void> Function(AppState state)? onSave;
  final LocalAnimationStore? animationStore;
  final JudgeService judgeService;
  late final Timer _timer;
  AppState state;
  bool _timerPaused = false;
  int compactIndex = 0;
  bool judgeAvailable = false;
  bool judging = false;
  JudgeResult? judgeResult;
  bool importingAnimation = false;
  String? animationError;

  int get elapsedSeconds => state.timerSeconds[problem.slug] ?? 0;
  bool get timerPaused => _timerPaused;
  String get draft =>
      state.drafts['${problem.slug}:python'] ??
      problem.starterCodeByLanguage['python'] ??
      '';
  String get notes => state.notes[problem.slug] ?? '';
  String? get animationPath => state.animationPaths[problem.slug];

  Future<void> refreshJudgeAvailability() async {
    judgeAvailable = await judgeService.isAvailable();
    notifyListeners();
  }

  Future<void> runTests({required bool submit}) async {
    judging = true;
    notifyListeners();
    final cases = problem.testCases
        .where((test) => submit || test.sample)
        .map((test) => JudgeTestInput(id: test.id, values: test.input))
        .toList();
    judgeResult = await judgeService.run(
      JudgeRequest(
        problemSlug: problem.slug,
        language: 'python',
        sourceCode: draft,
        submit: submit,
        selectedTests: cases.map((test) => test.id).toList(),
      ),
      cases,
    );
    judgeAvailable = judgeResult!.status != JudgeStatus.unavailable;
    judging = false;
    final previous = state.testHistory[problem.slug] ?? const <String>[];
    state = state.copyWith(
      testHistory: {
        ...state.testHistory,
        problem.slug: [
          ...previous.skip(previous.length > 99 ? previous.length - 99 : 0),
          '${judgeResult!.status.name}:${judgeResult!.passedTests}/${judgeResult!.totalTests}',
        ],
      },
    );
    if (submit && judgeResult!.status == JudgeStatus.passed) markSolved();
    _save();
    notifyListeners();
  }

  Future<void> importAnimation() async {
    final store = animationStore;

    if (store == null || importingAnimation) return;

    importingAnimation = true;
    animationError = null;
    notifyListeners();

    try {
      final path = await store.importForProblem(problem.slug);

      if (path == null) return;

      state = state.copyWith(
        animationPaths: {...state.animationPaths, problem.slug: path},
      );
      _changed();
    } on Object catch (error) {
      animationError = 'Animation import failed: $error';
    } finally {
      importingAnimation = false;
      notifyListeners();
    }
  }

  Future<void> removeAnimation() async {
    final store = animationStore;

    if (store == null || importingAnimation || animationPath == null) {
      return;
    }

    importingAnimation = true;
    animationError = null;
    notifyListeners();

    try {
      await store.removeForProblem(problem.slug);

      final paths = {...state.animationPaths}..remove(problem.slug);

      state = state.copyWith(animationPaths: paths);
      _changed();
    } on Object catch (error) {
      animationError = 'Animation removal failed: $error';
    } finally {
      importingAnimation = false;
      notifyListeners();
    }
  }

  void toggleFocus() {
    state = state.copyWith(focusMode: !state.focusMode);
    _changed();
  }

  void toggleTimer() {
    _timerPaused = !_timerPaused;
    _save();
    notifyListeners();
  }

  void setCompactIndex(int value) {
    compactIndex = value;
    notifyListeners();
  }

  void selectProblem(Problem value) {
    problem = value;
    judgeResult = null;
    animationError = null;
    state = state.copyWith(
      selectedProblemSlug: value.slug,
      progress: {
        ...state.progress,
        if (state.progress[value.slug] != 'solved') value.slug: 'attempted',
      },
    );
    _changed();
  }

  void selectAdjacent(int offset) {
    final index = problems.indexWhere((value) => value.slug == problem.slug);
    if (index < 0) return;
    selectProblem(problems[(index + offset) % problems.length]);
  }

  void updateDraft(String value) {
    state = state.copyWith(
      drafts: {...state.drafts, '${problem.slug}:python': value},
    );
    _save();
  }

  void updateNotes(String value) {
    state = state.copyWith(notes: {...state.notes, problem.slug: value});
    _save();
  }

  void markSolved() {
    state = state.copyWith(
      progress: {...state.progress, problem.slug: 'solved'},
    );
    _changed();
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  void _save() {
    onSave?.call(state);
  }

  @override
  void dispose() {
    _timer.cancel();
    _save();
    super.dispose();
  }
}
