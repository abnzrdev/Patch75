import '../../features/materials/learning_material.dart';
import '../../features/custom_tests/custom_test_case.dart';
import '../../features/review/review_attempt.dart';
import '../../features/review/review_models.dart';

class AppState {
  const AppState({
    this.schemaVersion = currentSchemaVersion,
    this.selectedProblemSlug = 'two-sum',
    this.drafts = const {},
    this.notes = const {},
    this.timerSeconds = const {},
    this.focusMode = false,
    this.progress = const {},
    this.testHistory = const {},
    this.animationPaths = const {},
    this.materials = const {},
    this.reviewRecords = const {},
    this.reviewAttempts = const {},
    this.activeReviewAttemptId,
    this.customTests = const {},
    this.settings = const {},
    this.importedDataVersion = 1,
  });

  factory AppState.fromJson(Map<String, Object?> json) => AppState(
    selectedProblemSlug:
        (json['selectedProblemSlug'] ?? json['selectedProblem'] ?? 'two-sum')
            as String,
    drafts: _stringMap(json['drafts']),
    notes: _stringMap(json['notes']),
    timerSeconds: (json['timerSeconds'] as Map? ?? const {}).map(
      (key, value) => MapEntry(key as String, value as int),
    ),
    focusMode: json['focusMode'] as bool? ?? false,
    progress: _stringMap(json['progress']),
    testHistory: (json['testHistory'] as Map? ?? const {}).map(
      (key, value) => MapEntry(key as String, List<String>.from(value as List)),
    ),
    animationPaths: _stringMap(json['animationPaths']),
    materials: (json['materials'] as Map? ?? const {}).map(
      (key, value) => MapEntry(
        key as String,
        (value as List)
            .map(
              (item) => LearningMaterial.fromJson(
                Map<String, Object?>.from(item as Map),
              ),
            )
            .toList(),
      ),
    ),
    reviewRecords: (json['reviewRecords'] as Map? ?? const {}).map(
      (key, value) => MapEntry(
        key as String,
        ReviewRecord.fromJson(Map<String, Object?>.from(value as Map)),
      ),
    ),
    reviewAttempts: (json['reviewAttempts'] as Map? ?? const {}).map(
      (key, value) => MapEntry(
        key as String,
        ReviewAttempt.fromJson(Map<String, Object?>.from(value as Map)),
      ),
    ),
    activeReviewAttemptId: json['activeReviewAttemptId'] as String?,
    customTests: (json['customTests'] as Map? ?? const {}).map(
      (key, value) => MapEntry(
        key as String,
        (value as List)
            .map(
              (item) => CustomTestCase.fromJson(
                Map<String, Object?>.from(item as Map),
              ),
            )
            .toList(),
      ),
    ),
    settings: Map<String, Object?>.from(json['settings'] as Map? ?? const {}),
    importedDataVersion: json['importedDataVersion'] as int? ?? 1,
  );

  static const currentSchemaVersion = 6;

  final int schemaVersion;
  final String selectedProblemSlug;
  final Map<String, String> drafts;
  final Map<String, String> notes;
  final Map<String, int> timerSeconds;
  final bool focusMode;
  final Map<String, String> progress;
  final Map<String, List<String>> testHistory;
  final Map<String, String> animationPaths;
  final Map<String, List<LearningMaterial>> materials;
  final Map<String, ReviewRecord> reviewRecords;
  final Map<String, ReviewAttempt> reviewAttempts;
  final String? activeReviewAttemptId;
  final Map<String, List<CustomTestCase>> customTests;
  final Map<String, Object?> settings;
  final int importedDataVersion;

  AppState copyWith({
    String? selectedProblemSlug,
    Map<String, String>? drafts,
    Map<String, String>? notes,
    Map<String, int>? timerSeconds,
    bool? focusMode,
    Map<String, String>? progress,
    Map<String, List<String>>? testHistory,
    Map<String, String>? animationPaths,
    Map<String, List<LearningMaterial>>? materials,
    Map<String, ReviewRecord>? reviewRecords,
    Map<String, ReviewAttempt>? reviewAttempts,
    Object? activeReviewAttemptId = _unset,
    Map<String, List<CustomTestCase>>? customTests,
    Map<String, Object?>? settings,
    int? importedDataVersion,
  }) => AppState(
    selectedProblemSlug: selectedProblemSlug ?? this.selectedProblemSlug,
    drafts: drafts ?? this.drafts,
    notes: notes ?? this.notes,
    timerSeconds: timerSeconds ?? this.timerSeconds,
    focusMode: focusMode ?? this.focusMode,
    progress: progress ?? this.progress,
    testHistory: testHistory ?? this.testHistory,
    animationPaths: animationPaths ?? this.animationPaths,
    materials: materials ?? this.materials,
    reviewRecords: reviewRecords ?? this.reviewRecords,
    reviewAttempts: reviewAttempts ?? this.reviewAttempts,
    activeReviewAttemptId: activeReviewAttemptId == _unset
        ? this.activeReviewAttemptId
        : activeReviewAttemptId as String?,
    customTests: customTests ?? this.customTests,
    settings: settings ?? this.settings,
    importedDataVersion: importedDataVersion ?? this.importedDataVersion,
  );

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'selectedProblemSlug': selectedProblemSlug,
    'drafts': drafts,
    'notes': notes,
    'timerSeconds': timerSeconds,
    'focusMode': focusMode,
    'progress': progress,
    'testHistory': testHistory,
    'animationPaths': animationPaths,
    'materials': materials.map(
      (key, value) =>
          MapEntry(key, value.map((item) => item.toJson()).toList()),
    ),
    'reviewRecords': reviewRecords.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'reviewAttempts': reviewAttempts.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'activeReviewAttemptId': activeReviewAttemptId,
    'customTests': customTests.map(
      (key, value) =>
          MapEntry(key, value.map((item) => item.toJson()).toList()),
    ),
    'settings': settings,
    'importedDataVersion': importedDataVersion,
  };

  @override
  bool operator ==(Object other) =>
      other is AppState &&
      schemaVersion == other.schemaVersion &&
      selectedProblemSlug == other.selectedProblemSlug &&
      _mapsEqual(drafts, other.drafts) &&
      _mapsEqual(notes, other.notes) &&
      _mapsEqual(timerSeconds, other.timerSeconds) &&
      focusMode == other.focusMode &&
      _mapsEqual(progress, other.progress) &&
      _historyEqual(testHistory, other.testHistory) &&
      _mapsEqual(animationPaths, other.animationPaths) &&
      _materialMapsEqual(materials, other.materials) &&
      _mapsEqual(reviewRecords, other.reviewRecords) &&
      _mapsEqual(reviewAttempts, other.reviewAttempts) &&
      activeReviewAttemptId == other.activeReviewAttemptId &&
      _customTestMapsEqual(customTests, other.customTests) &&
      _mapsEqual(settings, other.settings) &&
      importedDataVersion == other.importedDataVersion;

  @override
  int get hashCode => Object.hash(
    schemaVersion,
    selectedProblemSlug,
    Object.hashAllUnordered(drafts.entries),
    Object.hashAllUnordered(notes.entries),
    Object.hashAllUnordered(timerSeconds.entries),
    focusMode,
    Object.hashAllUnordered(progress.entries),
    Object.hashAllUnordered(
      testHistory.entries.map(
        (entry) => Object.hash(entry.key, Object.hashAll(entry.value)),
      ),
    ),
    Object.hashAllUnordered(animationPaths.entries),
    Object.hashAllUnordered(
      materials.entries.map(
        (entry) => Object.hash(entry.key, Object.hashAll(entry.value)),
      ),
    ),
    Object.hashAllUnordered(reviewRecords.entries),
    Object.hashAllUnordered(reviewAttempts.entries),
    activeReviewAttemptId,
    Object.hashAllUnordered(
      customTests.entries.map(
        (entry) => Object.hash(entry.key, Object.hashAll(entry.value)),
      ),
    ),
    Object.hashAllUnordered(settings.entries),
    importedDataVersion,
  );
}

const _unset = Object();

Map<String, String> _stringMap(Object? value) => Map<String, Object?>.from(
  value as Map? ?? const {},
).map((key, value) => MapEntry(key, value as String));

bool _mapsEqual(Map<Object?, Object?> left, Map<Object?, Object?> right) =>
    left.length == right.length &&
    left.entries.every((entry) => right[entry.key] == entry.value);

bool _historyEqual(
  Map<String, List<String>> left,
  Map<String, List<String>> right,
) =>
    left.length == right.length &&
    left.entries.every((entry) {
      final values = right[entry.key];

      return values != null &&
          values.length == entry.value.length &&
          values.indexed.every((item) => item.$2 == entry.value[item.$1]);
    });

bool _materialMapsEqual(
  Map<String, List<LearningMaterial>> left,
  Map<String, List<LearningMaterial>> right,
) =>
    left.length == right.length &&
    left.entries.every((entry) {
      final values = right[entry.key];
      return values != null &&
          values.length == entry.value.length &&
          values.indexed.every((item) => item.$2 == entry.value[item.$1]);
    });

bool _customTestMapsEqual(
  Map<String, List<CustomTestCase>> left,
  Map<String, List<CustomTestCase>> right,
) =>
    left.length == right.length &&
    left.entries.every((entry) {
      final values = right[entry.key];
      return values != null &&
          values.length == entry.value.length &&
          values.indexed.every((item) => item.$2 == entry.value[item.$1]);
    });
