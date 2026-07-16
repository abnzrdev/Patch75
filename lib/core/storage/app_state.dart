class AppState {
  const AppState({
    this.schemaVersion = currentSchemaVersion,
    this.selectedProblemSlug = 'two-sum',
    this.drafts = const {},
    this.notes = const {},
    this.timerSeconds = const {},
    this.focusMode = false,
    this.progress = const {},
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
  );

  static const currentSchemaVersion = 2;

  final int schemaVersion;
  final String selectedProblemSlug;
  final Map<String, String> drafts;
  final Map<String, String> notes;
  final Map<String, int> timerSeconds;
  final bool focusMode;
  final Map<String, String> progress;

  AppState copyWith({
    String? selectedProblemSlug,
    Map<String, String>? drafts,
    Map<String, String>? notes,
    Map<String, int>? timerSeconds,
    bool? focusMode,
    Map<String, String>? progress,
  }) => AppState(
    selectedProblemSlug: selectedProblemSlug ?? this.selectedProblemSlug,
    drafts: drafts ?? this.drafts,
    notes: notes ?? this.notes,
    timerSeconds: timerSeconds ?? this.timerSeconds,
    focusMode: focusMode ?? this.focusMode,
    progress: progress ?? this.progress,
  );

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'selectedProblemSlug': selectedProblemSlug,
    'drafts': drafts,
    'notes': notes,
    'timerSeconds': timerSeconds,
    'focusMode': focusMode,
    'progress': progress,
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
      _mapsEqual(progress, other.progress);

  @override
  int get hashCode => Object.hash(
    schemaVersion,
    selectedProblemSlug,
    Object.hashAllUnordered(drafts.entries),
    Object.hashAllUnordered(notes.entries),
    Object.hashAllUnordered(timerSeconds.entries),
    focusMode,
    Object.hashAllUnordered(progress.entries),
  );
}

Map<String, String> _stringMap(Object? value) => Map<String, Object?>.from(
  value as Map? ?? const {},
).map((key, value) => MapEntry(key, value as String));

bool _mapsEqual(Map<Object?, Object?> left, Map<Object?, Object?> right) =>
    left.length == right.length &&
    left.entries.every((entry) => right[entry.key] == entry.value);
