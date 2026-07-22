import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/storage/app_state.dart';
import '../features/custom_tests/custom_test_case.dart';
import '../features/custom_tests/custom_test_repository.dart';
import '../features/animations/local_animation_store.dart';
import '../features/judge/judge_models.dart';
import '../features/judge/judge_service.dart';
import '../features/materials/learning_material.dart';
import '../features/materials/local_material_store.dart';
import '../features/problems/problem.dart';
import '../features/learning/complexity_checker.dart';
import '../features/review/fsrs_scheduler_service.dart';
import '../features/review/review_attempt.dart';
import '../features/review/review_models.dart';
import '../features/review/review_repository.dart';

class AppController extends ChangeNotifier {
  AppController({
    required Problem problem,
    List<Problem>? problems,
    required this.state,
    this.onSave,
    this.animationStore,
    this.materialStore,
    this.materialOpener,
    ReviewSchedulerService? reviewScheduler,
    ReviewRepository? reviewRepository,
    DateTime Function()? now,
    this.platformName = 'unknown',
    JudgeService? judgeService,
  }) : problem = problem,
       problems = problems ?? [problem],
       judgeService = judgeService ?? const UnsupportedJudgeService(),
       reviewScheduler = reviewScheduler ?? FsrsSchedulerService(),
       now = now ?? DateTime.now {
    this.reviewRepository =
        reviewRepository ?? LocalReviewRepository(this.reviewScheduler);
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
  ReviewSchedulerService reviewScheduler;
  late final ReviewRepository reviewRepository;
  final DateTime Function() now;
  final String platformName;
  late final Timer _timer;
  AppState state;
  bool _timerPaused = false;
  int compactIndex = 0;
  bool judgeAvailable = false;
  bool judging = false;
  JudgeResult? judgeResult;
  JudgeResult? customJudgeResult;
  bool importingAnimation = false;
  String? animationError;
  bool importingMaterial = false;
  String? materialError;
  final Map<String, List<int>> _practiceHints = {};

  ReviewAttempt? get activeReviewAttempt => state.activeReviewAttemptId == null
      ? null
      : state.reviewAttempts[state.activeReviewAttemptId];
  List<ReviewQueueItem> get reviewQueue =>
      reviewRepository.queue(state.reviewRecords, nowUtc: now().toUtc());
  int get dueReviewCount => reviewQueue
      .where((item) => item.bucket != ReviewQueueBucket.upcoming)
      .length;
  int get activeReviewElapsedMilliseconds {
    final attempt = activeReviewAttempt;
    if (attempt == null) return 0;
    return ReviewTimer.fromJson(attempt.timer).elapsedAt(now().toUtc());
  }

  int reviewTargetMinutes(String difficulty) =>
      (state.settings['reviewTarget${difficulty.toLowerCase()}Minutes']
          as int?) ??
      switch (difficulty.toLowerCase()) {
        'easy' => 20,
        'hard' => 50,
        _ => 35,
      };

  Future<void> initializeReviews() async {
    final records = await reviewRepository.migrateSolved(
      progress: state.progress,
      records: state.reviewRecords,
      nowUtc: now().toUtc(),
    );
    if (mapEquals(records, state.reviewRecords)) return;
    state = state.copyWith(reviewRecords: records);
    _changed();
  }

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

  List<CustomTestCase> get customTests =>
      state.customTests[problem.slug] ?? const [];
  List<int> get revealedHintLevels =>
      activeReviewAttempt?.problemSlug == problem.slug
      ? activeReviewAttempt!.hintsUsed
      : _practiceHints[problem.slug] ?? const [];

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
    _recordJudgeTelemetry(submit: submit, result: judgeResult!);
    if (submit && judgeResult!.status == JudgeStatus.passed) {
      markSolved();
      await _ensureReviewCard(problem.slug);
    }
    _save();
    notifyListeners();
  }

  void revealNextHint() {
    final next = revealedHintLevels.length + 1;
    if (next > problem.hints.length || next > 3) return;
    final attempt = activeReviewAttempt;
    if (attempt != null && attempt.problemSlug == problem.slug) {
      _replaceAttempt(
        attempt.copyWith(
          hintsUsed: [...attempt.hintsUsed, next],
          updatedAtUtc: now().toUtc(),
        ),
      );
    } else {
      _practiceHints[problem.slug] = [...revealedHintLevels, next];
      notifyListeners();
    }
  }

  ComplexityComparison recordComplexityAnswers(
    String timeComplexity,
    String spaceComplexity,
  ) {
    final comparison = compareComplexity(
      timeComplexity,
      problem.expectedTimeComplexity,
      spaceComplexity,
      problem.expectedSpaceComplexity,
    );
    final attempt = activeReviewAttempt;
    if (attempt != null && attempt.problemSlug == problem.slug) {
      _replaceAttempt(
        attempt.copyWith(
          timeComplexity: timeComplexity,
          spaceComplexity: spaceComplexity,
          updatedAtUtc: now().toUtc(),
        ),
      );
    }
    return comparison;
  }

  void saveCustomTest({
    String? id,
    required String name,
    required Map<String, Object?> input,
  }) {
    final instant = now().toUtc();
    final existing = id == null
        ? null
        : customTests.where((item) => item.id == id).firstOrNull;
    final value = existing == null
        ? CustomTestCase.create(
            id: 'custom-${problem.slug}-${instant.microsecondsSinceEpoch}',
            problemSlug: problem.slug,
            name: name,
            input: input,
            nowUtc: instant,
          )
        : existing.copyWith(name: name, input: input, updatedAtUtc: instant);
    final values = _customRepository.save(customTests, value);
    _setCustomTests(values);
  }

  void deleteCustomTest(String id) =>
      _setCustomTests(_customRepository.delete(customTests, id));

  void duplicateCustomTest(String id) => _setCustomTests(
    _customRepository.duplicate(customTests, id, nowUtc: now().toUtc()),
  );

  void toggleCustomTest(String id, bool enabled) => _setCustomTests(
    _customRepository.toggle(customTests, id, enabled, nowUtc: now().toUtc()),
  );

  void reorderCustomTests(int oldIndex, int newIndex) => _setCustomTests(
    _customRepository.reorder(customTests, oldIndex, newIndex),
  );

  Future<void> runCustomTests({CustomTestCase? selected}) async {
    final values = selected == null
        ? customTests.where((item) => item.enabled).toList()
        : [selected];
    if (values.isEmpty) return;
    judging = true;
    customJudgeResult = null;
    notifyListeners();
    final inputs = [
      for (final value in values)
        JudgeTestInput(id: value.id, values: value.input),
    ];
    customJudgeResult = await judgeService.run(
      JudgeRequest(
        problemSlug: problem.slug,
        language: 'python',
        sourceCode: draft,
        selectedTests: inputs.map((item) => item.id).toList(),
      ),
      inputs,
    );
    judging = false;
    final attempt = activeReviewAttempt;
    if (attempt != null) {
      _replaceAttempt(
        attempt.copyWith(
          customTestsUsed: attempt.customTestsUsed + values.length,
          updatedAtUtc: now().toUtc(),
        ),
        notify: false,
      );
    }
    _changed();
  }

  LocalCustomTestRepository get _customRepository =>
      LocalCustomTestRepository(requiredFields: problem.inputFieldTypes);

  void _setCustomTests(List<CustomTestCase> values) {
    state = state.copyWith(
      customTests: {...state.customTests, problem.slug: values},
    );
    _changed();
  }

  Future<void> startReview(Problem value) async {
    selectProblem(value);
    await _ensureReviewCard(value.slug);
    final instant = now().toUtc();
    final id = 'attempt-${value.slug}-${instant.microsecondsSinceEpoch}';
    final attempt = ReviewAttempt.start(
      id: id,
      problemSlug: value.slug,
      startedAtUtc: instant,
      isFsrsReview: true,
      dueDateBeforeUtc: state.reviewRecords[value.slug]?.nextDueUtc,
      platform: platformName,
    );
    state = state.copyWith(
      reviewAttempts: {...state.reviewAttempts, id: attempt},
      activeReviewAttemptId: id,
    );
    _changed();
  }

  void toggleReviewPause() {
    final attempt = activeReviewAttempt;
    if (attempt == null) return;
    final timer = ReviewTimer.fromJson(attempt.timer);
    if (timer.paused) {
      timer.resume(now().toUtc());
    } else {
      timer.pause(now().toUtc());
    }
    _replaceAttempt(
      attempt.copyWith(timer: timer.toJson(), updatedAtUtc: now()),
    );
  }

  void abandonReview() {
    final attempt = activeReviewAttempt;
    if (attempt == null) return;
    final instant = now().toUtc();
    final timer = ReviewTimer.fromJson(attempt.timer)..pause(instant);
    _replaceAttempt(
      attempt
          .finish(
            finishedAtUtc: instant,
            elapsedMilliseconds: timer.elapsedAt(instant),
            abandoned: true,
          )
          .copyWith(timer: timer.toJson()),
      clearActive: true,
    );
  }

  Future<ReviewScheduleResult?> rateActiveReview(ReviewRating rating) async {
    final attempt = activeReviewAttempt;
    final record = attempt == null
        ? null
        : state.reviewRecords[attempt.problemSlug];
    if (attempt == null || record == null) return null;
    final instant = now().toUtc();
    final timer = ReviewTimer.fromJson(attempt.timer)..pause(instant);
    final scheduled = await reviewScheduler.rate(
      record,
      rating,
      reviewedAtUtc: instant,
      reviewDurationMs: timer.elapsedAt(instant),
    );
    final finished = attempt
        .finish(
          finishedAtUtc: instant,
          elapsedMilliseconds: timer.elapsedAt(instant),
        )
        .copyWith(
          fsrsRating: rating,
          dueDateAfterUtc: scheduled.record.nextDueUtc,
          timer: timer.toJson(),
        );
    state = state.copyWith(
      reviewRecords: {
        ...state.reviewRecords,
        record.problemSlug: scheduled.record,
      },
      reviewAttempts: {...state.reviewAttempts, finished.id: finished},
      activeReviewAttemptId: null,
    );
    _changed();
    return scheduled;
  }

  Future<Map<ReviewRating, Duration>> previewReviewIntervals() async {
    final attempt = activeReviewAttempt;
    final record = attempt == null
        ? null
        : state.reviewRecords[attempt.problemSlug];
    if (record == null) return const {};
    final instant = now().toUtc();
    return {
      for (final rating in ReviewRating.values)
        rating: (await reviewScheduler.rate(
          record,
          rating,
          reviewedAtUtc: instant,
        )).nextInterval,
    };
  }

  void postponeReview(
    ReviewRecord record, {
    Duration by = const Duration(days: 1),
  }) {
    final due = now().toUtc().add(by);
    final card = {...record.card, 'due': due.toIso8601String()};
    state = state.copyWith(
      reviewRecords: {
        ...state.reviewRecords,
        record.problemSlug: record.copyWith(
          card: card,
          nextDueUtc: due,
          updatedAtUtc: now().toUtc(),
        ),
      },
    );
    _changed();
  }

  void updateReviewSettings({
    double? desiredRetention,
    int? easyMinutes,
    int? mediumMinutes,
    int? hardMinutes,
  }) {
    if (desiredRetention != null &&
        (desiredRetention < 0.70 || desiredRetention > 0.99)) {
      throw ArgumentError.value(desiredRetention, 'desiredRetention');
    }
    for (final value in [easyMinutes, mediumMinutes, hardMinutes]) {
      if (value != null && (value < 1 || value > 240)) {
        throw ArgumentError.value(value, 'review target minutes');
      }
    }
    final settings = {...state.settings};
    if (desiredRetention != null) {
      settings['desiredRetention'] = desiredRetention;
      reviewScheduler = FsrsSchedulerService(
        desiredRetention: desiredRetention,
      );
    }
    if (easyMinutes != null) settings['reviewTargeteasyMinutes'] = easyMinutes;
    if (mediumMinutes != null) {
      settings['reviewTargetmediumMinutes'] = mediumMinutes;
    }
    if (hardMinutes != null) settings['reviewTargethardMinutes'] = hardMinutes;
    state = state.copyWith(settings: settings);
    _changed();
  }

  Future<void> _ensureReviewCard(String slug) async {
    if (state.reviewRecords.containsKey(slug)) return;
    final record = await reviewScheduler.createCard(
      slug,
      nowUtc: now().toUtc(),
    );
    state = state.copyWith(
      reviewRecords: {...state.reviewRecords, slug: record},
    );
  }

  void _recordJudgeTelemetry({
    required bool submit,
    required JudgeResult result,
  }) {
    final attempt = activeReviewAttempt;
    if (attempt == null) return;
    _replaceAttempt(
      attempt.copyWith(
        runTestCount: attempt.runTestCount + (submit ? 0 : 1),
        submitCount: attempt.submitCount + (submit ? 1 : 0),
        passedTests: result.passedTests,
        totalTests: result.totalTests,
        successful: submit && result.status == JudgeStatus.passed
            ? true
            : attempt.successful,
        finalSubmissionResult: submit
            ? result.status.name
            : attempt.finalSubmissionResult,
        updatedAtUtc: now().toUtc(),
      ),
      notify: false,
    );
  }

  void _replaceAttempt(
    ReviewAttempt attempt, {
    bool clearActive = false,
    bool notify = true,
  }) {
    state = state.copyWith(
      reviewAttempts: {...state.reviewAttempts, attempt.id: attempt},
      activeReviewAttemptId: clearActive ? null : state.activeReviewAttemptId,
    );
    if (notify) _changed();
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
