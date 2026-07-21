import 'review_models.dart';

class ReviewTimer {
  ReviewTimer({
    required DateTime startedAtUtc,
    this.accumulatedMilliseconds = 0,
    DateTime? activeSinceUtc,
  }) : startedAtUtc = startedAtUtc.toUtc(),
       activeSinceUtc = (activeSinceUtc ?? startedAtUtc).toUtc();

  factory ReviewTimer.fromJson(Map<String, Object?> json) =>
      ReviewTimer(
          startedAtUtc: DateTime.parse(json['startedAtUtc'] as String).toUtc(),
          accumulatedMilliseconds: json['accumulatedMilliseconds'] as int? ?? 0,
          activeSinceUtc: json['activeSinceUtc'] == null
              ? null
              : DateTime.parse(json['activeSinceUtc'] as String).toUtc(),
        )
        ..activeSinceUtc = json['paused'] == true
            ? null
            : DateTime.parse(json['activeSinceUtc'] as String).toUtc();

  final DateTime startedAtUtc;
  int accumulatedMilliseconds;
  DateTime? activeSinceUtc;

  bool get paused => activeSinceUtc == null;

  int elapsedAt(DateTime nowUtc) =>
      accumulatedMilliseconds +
      (activeSinceUtc == null
          ? 0
          : nowUtc.toUtc().difference(activeSinceUtc!).inMilliseconds);

  void pause(DateTime nowUtc) {
    if (activeSinceUtc == null) return;
    accumulatedMilliseconds = elapsedAt(nowUtc);
    activeSinceUtc = null;
  }

  void resume(DateTime nowUtc) {
    activeSinceUtc ??= nowUtc.toUtc();
  }

  Map<String, Object?> toJson() => {
    'startedAtUtc': startedAtUtc.toIso8601String(),
    'accumulatedMilliseconds': accumulatedMilliseconds,
    'activeSinceUtc': activeSinceUtc?.toIso8601String(),
    'paused': paused,
  };
}

class ReviewAttempt {
  const ReviewAttempt({
    required this.id,
    required this.problemSlug,
    required this.startedAtUtc,
    required this.finishedAtUtc,
    required this.elapsedMilliseconds,
    required this.isFsrsReview,
    required this.runTestCount,
    required this.submitCount,
    required this.passedTests,
    required this.totalTests,
    required this.hintsUsed,
    required this.customTestsUsed,
    required this.timeComplexity,
    required this.spaceComplexity,
    required this.fsrsRating,
    required this.dueDateBeforeUtc,
    required this.dueDateAfterUtc,
    required this.platform,
    required this.whatWentWrong,
    required this.successful,
    required this.finalSubmissionResult,
    required this.abandoned,
    required this.timer,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.schemaVersion = 1,
  });

  factory ReviewAttempt.start({
    required String id,
    required String problemSlug,
    required DateTime startedAtUtc,
    required bool isFsrsReview,
    required DateTime? dueDateBeforeUtc,
    required String platform,
  }) {
    _validateStableId(id);
    _validateSlug(problemSlug);
    final start = startedAtUtc.toUtc();
    return ReviewAttempt(
      id: id,
      problemSlug: problemSlug,
      startedAtUtc: start,
      finishedAtUtc: null,
      elapsedMilliseconds: 0,
      isFsrsReview: isFsrsReview,
      runTestCount: 0,
      submitCount: 0,
      passedTests: 0,
      totalTests: 0,
      hintsUsed: const [],
      customTestsUsed: 0,
      timeComplexity: null,
      spaceComplexity: null,
      fsrsRating: null,
      dueDateBeforeUtc: dueDateBeforeUtc?.toUtc(),
      dueDateAfterUtc: null,
      platform: platform,
      whatWentWrong: null,
      successful: false,
      finalSubmissionResult: null,
      abandoned: false,
      timer: ReviewTimer(startedAtUtc: start).toJson(),
      createdAtUtc: start,
      updatedAtUtc: start,
    );
  }

  factory ReviewAttempt.fromJson(Map<String, Object?> json) {
    final id = json['id'] as String;
    final slug = json['problemSlug'] as String;
    _validateStableId(id);
    _validateSlug(slug);
    return ReviewAttempt(
      id: id,
      problemSlug: slug,
      startedAtUtc: _utc(json['startedAtUtc'])!,
      finishedAtUtc: _utc(json['finishedAtUtc']),
      elapsedMilliseconds: json['elapsedMilliseconds'] as int? ?? 0,
      isFsrsReview: json['isFsrsReview'] as bool? ?? false,
      runTestCount: json['runTestCount'] as int? ?? 0,
      submitCount: json['submitCount'] as int? ?? 0,
      passedTests: json['passedTests'] as int? ?? 0,
      totalTests: json['totalTests'] as int? ?? 0,
      hintsUsed: List<int>.from(json['hintsUsed'] as List? ?? const []),
      customTestsUsed: json['customTestsUsed'] as int? ?? 0,
      timeComplexity: json['timeComplexity'] as String?,
      spaceComplexity: json['spaceComplexity'] as String?,
      fsrsRating: json['fsrsRating'] == null
          ? null
          : ReviewRating.values.byName(json['fsrsRating'] as String),
      dueDateBeforeUtc: _utc(json['dueDateBeforeUtc']),
      dueDateAfterUtc: _utc(json['dueDateAfterUtc']),
      platform: json['platform'] as String? ?? 'unknown',
      whatWentWrong: json['whatWentWrong'] as String?,
      successful: json['successful'] as bool? ?? false,
      finalSubmissionResult: json['finalSubmissionResult'] as String?,
      abandoned: json['abandoned'] as bool? ?? false,
      timer: Map<String, Object?>.from(json['timer'] as Map? ?? const {}),
      createdAtUtc: _utc(json['createdAtUtc'])!,
      updatedAtUtc: _utc(json['updatedAtUtc'])!,
      schemaVersion: json['schemaVersion'] as int? ?? 1,
    );
  }

  final int schemaVersion;
  final String id;
  final String problemSlug;
  final DateTime startedAtUtc;
  final DateTime? finishedAtUtc;
  final int elapsedMilliseconds;
  final bool isFsrsReview;
  final int runTestCount;
  final int submitCount;
  final int passedTests;
  final int totalTests;
  final List<int> hintsUsed;
  final int customTestsUsed;
  final String? timeComplexity;
  final String? spaceComplexity;
  final ReviewRating? fsrsRating;
  final DateTime? dueDateBeforeUtc;
  final DateTime? dueDateAfterUtc;
  final String platform;
  final String? whatWentWrong;
  final bool successful;
  final String? finalSubmissionResult;
  final bool abandoned;
  final Map<String, Object?> timer;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  ReviewAttempt finish({
    required DateTime finishedAtUtc,
    required int elapsedMilliseconds,
    bool abandoned = false,
  }) => copyWith(
    finishedAtUtc: finishedAtUtc.toUtc(),
    elapsedMilliseconds: elapsedMilliseconds,
    abandoned: abandoned,
    updatedAtUtc: finishedAtUtc.toUtc(),
  );

  ReviewAttempt copyWith({
    Object? finishedAtUtc = _unset,
    int? elapsedMilliseconds,
    int? runTestCount,
    int? submitCount,
    int? passedTests,
    int? totalTests,
    List<int>? hintsUsed,
    int? customTestsUsed,
    Object? timeComplexity = _unset,
    Object? spaceComplexity = _unset,
    Object? fsrsRating = _unset,
    Object? dueDateAfterUtc = _unset,
    Object? whatWentWrong = _unset,
    bool? successful,
    Object? finalSubmissionResult = _unset,
    bool? abandoned,
    Map<String, Object?>? timer,
    DateTime? updatedAtUtc,
  }) => ReviewAttempt(
    schemaVersion: schemaVersion,
    id: id,
    problemSlug: problemSlug,
    startedAtUtc: startedAtUtc,
    finishedAtUtc: finishedAtUtc == _unset
        ? this.finishedAtUtc
        : finishedAtUtc as DateTime?,
    elapsedMilliseconds: elapsedMilliseconds ?? this.elapsedMilliseconds,
    isFsrsReview: isFsrsReview,
    runTestCount: runTestCount ?? this.runTestCount,
    submitCount: submitCount ?? this.submitCount,
    passedTests: passedTests ?? this.passedTests,
    totalTests: totalTests ?? this.totalTests,
    hintsUsed: hintsUsed ?? this.hintsUsed,
    customTestsUsed: customTestsUsed ?? this.customTestsUsed,
    timeComplexity: timeComplexity == _unset
        ? this.timeComplexity
        : timeComplexity as String?,
    spaceComplexity: spaceComplexity == _unset
        ? this.spaceComplexity
        : spaceComplexity as String?,
    fsrsRating: fsrsRating == _unset
        ? this.fsrsRating
        : fsrsRating as ReviewRating?,
    dueDateBeforeUtc: dueDateBeforeUtc,
    dueDateAfterUtc: dueDateAfterUtc == _unset
        ? this.dueDateAfterUtc
        : dueDateAfterUtc as DateTime?,
    platform: platform,
    whatWentWrong: whatWentWrong == _unset
        ? this.whatWentWrong
        : whatWentWrong as String?,
    successful: successful ?? this.successful,
    finalSubmissionResult: finalSubmissionResult == _unset
        ? this.finalSubmissionResult
        : finalSubmissionResult as String?,
    abandoned: abandoned ?? this.abandoned,
    timer: timer ?? this.timer,
    createdAtUtc: createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'problemSlug': problemSlug,
    'startedAtUtc': startedAtUtc.toUtc().toIso8601String(),
    'finishedAtUtc': finishedAtUtc?.toUtc().toIso8601String(),
    'elapsedMilliseconds': elapsedMilliseconds,
    'isFsrsReview': isFsrsReview,
    'runTestCount': runTestCount,
    'submitCount': submitCount,
    'passedTests': passedTests,
    'totalTests': totalTests,
    'hintsUsed': hintsUsed,
    'customTestsUsed': customTestsUsed,
    'timeComplexity': timeComplexity,
    'spaceComplexity': spaceComplexity,
    'fsrsRating': fsrsRating?.name,
    'dueDateBeforeUtc': dueDateBeforeUtc?.toUtc().toIso8601String(),
    'dueDateAfterUtc': dueDateAfterUtc?.toUtc().toIso8601String(),
    'platform': platform,
    'whatWentWrong': whatWentWrong,
    'successful': successful,
    'finalSubmissionResult': finalSubmissionResult,
    'abandoned': abandoned,
    'timer': timer,
    'createdAtUtc': createdAtUtc.toUtc().toIso8601String(),
    'updatedAtUtc': updatedAtUtc.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is ReviewAttempt && _deepEqual(toJson(), other.toJson());

  @override
  int get hashCode => Object.hash(id, updatedAtUtc);
}

const _unset = Object();

DateTime? _utc(Object? value) =>
    value == null ? null : DateTime.parse(value as String).toUtc();

void _validateSlug(String value) {
  if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(value)) {
    throw const FormatException('Invalid problem slug');
  }
}

void _validateStableId(String value) {
  if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(value)) {
    throw const FormatException('Invalid stable ID');
  }
}

bool _deepEqual(Object? left, Object? right) {
  if (left is Map && right is Map) {
    return left.length == right.length &&
        left.entries.every(
          (entry) => _deepEqual(entry.value, right[entry.key]),
        );
  }
  if (left is List && right is List) {
    return left.length == right.length &&
        left.indexed.every((item) => _deepEqual(item.$2, right[item.$1]));
  }
  return left == right;
}
