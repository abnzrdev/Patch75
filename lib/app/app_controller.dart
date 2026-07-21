import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/storage/app_state.dart';
import '../features/animations/local_animation_store.dart';
import '../features/judge/judge_models.dart';
import '../features/judge/judge_service.dart';
import '../features/materials/learning_material.dart';
import '../features/materials/local_material_store.dart';
import '../features/problems/problem.dart';

class AppController extends ChangeNotifier {
  AppController({
    required Problem problem,
    List<Problem>? problems,
    required this.state,
    this.onSave,
    this.animationStore,
    this.materialStore,
    this.materialOpener,
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
  final LocalMaterialStore? materialStore;
  final Future<String?> Function(LearningMaterial material)? materialOpener;
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
  bool importingMaterial = false;
  String? materialError;

  int get elapsedSeconds => state.timerSeconds[problem.slug] ?? 0;
  bool get timerPaused => _timerPaused;
  String get draft =>
      state.drafts['${problem.slug}:python'] ??
      problem.starterCodeByLanguage['python'] ??
      '';
  String get notes => state.notes[problem.slug] ?? '';
  String? get animationPath => state.animationPaths[problem.slug];
  List<LearningMaterial> get materials {
    final stored = state.materials[problem.slug] ?? const <LearningMaterial>[];
    final legacy = animationPath;
    if (legacy == null || stored.any((item) => item.path == legacy)) {
      return stored;
    }
    final file = File(legacy);
    final name = file.uri.pathSegments.last;
    final separator = name.lastIndexOf('.');
    final extension = separator < 0
        ? 'gif'
        : name.substring(separator + 1).toLowerCase();
    return [
      ...stored,
      LearningMaterial(
        id: 'legacy-animation',
        name: name,
        path: legacy,
        kind: LearningMaterialKind.image,
        extension: extension,
        sizeBytes: file.existsSync() ? file.lengthSync() : 0,
      ),
    ];
  }

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
    if (materialStore != null) {
      await _importMaterial(animation: true);
      return;
    }
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
    if (materialStore != null) {
      final current = materials.where((item) => item.path == animationPath);
      if (current.isNotEmpty && current.first.id != 'legacy-animation') {
        await removeMaterial(current.first);
        return;
      }
    }
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

  Future<void> addMaterial() => _importMaterial(animation: false);

  Future<void> _importMaterial({required bool animation}) async {
    final store = materialStore;
    if (store == null || importingMaterial) return;
    importingMaterial = true;
    importingAnimation = animation;
    materialError = null;
    animationError = null;
    notifyListeners();
    try {
      final material = await store.importForProblem(
        problem.slug,
        kinds: animation ? {LearningMaterialKind.image} : null,
      );
      if (material == null) return;
      final values = <LearningMaterial>[
        ...(state.materials[problem.slug] ?? const <LearningMaterial>[]),
        material,
      ];
      state = state.copyWith(
        materials: {...state.materials, problem.slug: values},
        animationPaths: animation
            ? {...state.animationPaths, problem.slug: material.path}
            : state.animationPaths,
      );
      notifyListeners();
      await onSave?.call(state);
    } on Object catch (error) {
      materialError = 'Material import failed: $error';
      if (animation) animationError = materialError;
    } finally {
      importingMaterial = false;
      importingAnimation = false;
      notifyListeners();
    }
  }

  Future<void> replaceMaterial(LearningMaterial old) async {
    final store = materialStore;
    if (store == null || importingMaterial || old.id == 'legacy-animation') {
      return;
    }
    importingMaterial = true;
    materialError = null;
    notifyListeners();
    try {
      final replacement = await store.importForProblem(
        problem.slug,
        replacing: old,
      );
      if (replacement == null) return;
      final values = <LearningMaterial>[
        for (final item
            in state.materials[problem.slug] ?? const <LearningMaterial>[])
          if (item.id == old.id) replacement else item,
      ];
      state = state.copyWith(
        materials: {...state.materials, problem.slug: values},
        animationPaths: animationPath == old.path
            ? {...state.animationPaths, problem.slug: replacement.path}
            : state.animationPaths,
      );
      notifyListeners();
      await onSave?.call(state);
      await store.delete(old, problem.slug);
    } on Object catch (error) {
      materialError = 'Material replacement failed: $error';
    } finally {
      importingMaterial = false;
      notifyListeners();
    }
  }

  Future<void> removeMaterial(LearningMaterial material) async {
    final store = materialStore;
    if (store == null || importingMaterial) return;
    if (material.id == 'legacy-animation') {
      await removeAnimation();
      return;
    }
    importingMaterial = true;
    materialError = null;
    notifyListeners();
    try {
      final values = <LearningMaterial>[
        for (final item
            in state.materials[problem.slug] ?? const <LearningMaterial>[])
          if (item.id != material.id) item,
      ];
      final paths = {...state.animationPaths};
      if (paths[problem.slug] == material.path) paths.remove(problem.slug);
      state = state.copyWith(
        materials: {...state.materials, problem.slug: values},
        animationPaths: paths,
      );
      notifyListeners();
      await onSave?.call(state);
      await store.delete(material, problem.slug);
    } on Object catch (error) {
      materialError = 'Material removal failed: $error';
    } finally {
      importingMaterial = false;
      notifyListeners();
    }
  }

  Future<void> openMaterial(LearningMaterial material) async {
    materialError = await materialOpener?.call(material);
    notifyListeners();
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
