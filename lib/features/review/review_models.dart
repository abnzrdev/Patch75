enum ReviewRating { again, hard, good, easy }

class ReviewEvent {
  const ReviewEvent({
    required this.id,
    required this.problemSlug,
    required this.rating,
    required this.reviewedAtUtc,
    required this.dueBeforeUtc,
    required this.dueAfterUtc,
    required this.fsrsLog,
    required this.createdAtUtc,
    this.schemaVersion = 1,
  });

  factory ReviewEvent.fromJson(Map<String, Object?> json) {
    final id = json['id'] as String;
    final slug = json['problemSlug'] as String;
    _validateId(id);
    _validateSlug(slug);
    return ReviewEvent(
      id: id,
      problemSlug: slug,
      rating: ReviewRating.values.byName(json['rating'] as String),
      reviewedAtUtc: _utc(json['reviewedAtUtc']),
      dueBeforeUtc: _utc(json['dueBeforeUtc']),
      dueAfterUtc: _utc(json['dueAfterUtc']),
      fsrsLog: Map<String, Object?>.from(json['fsrsLog'] as Map),
      createdAtUtc: _utc(json['createdAtUtc']),
      schemaVersion: json['schemaVersion'] as int? ?? 1,
    );
  }

  final int schemaVersion;
  final String id;
  final String problemSlug;
  final ReviewRating rating;
  final DateTime reviewedAtUtc;
  final DateTime dueBeforeUtc;
  final DateTime dueAfterUtc;
  final Map<String, Object?> fsrsLog;
  final DateTime createdAtUtc;

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'problemSlug': problemSlug,
    'rating': rating.name,
    'reviewedAtUtc': reviewedAtUtc.toUtc().toIso8601String(),
    'dueBeforeUtc': dueBeforeUtc.toUtc().toIso8601String(),
    'dueAfterUtc': dueAfterUtc.toUtc().toIso8601String(),
    'fsrsLog': fsrsLog,
    'createdAtUtc': createdAtUtc.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is ReviewEvent && _jsonEqual(toJson(), other.toJson());

  @override
  int get hashCode => Object.hash(id, problemSlug, reviewedAtUtc);
}

class ReviewRecord {
  const ReviewRecord({
    required this.id,
    required this.problemSlug,
    required this.card,
    required this.logs,
    required this.nextDueUtc,
    required this.lastReviewUtc,
    required this.state,
    required this.stability,
    required this.difficulty,
    required this.retrievability,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.schemaVersion = 1,
  });

  factory ReviewRecord.fromJson(Map<String, Object?> json) {
    final id = json['id'] as String;
    final slug = json['problemSlug'] as String;
    _validateId(id);
    _validateSlug(slug);
    return ReviewRecord(
      id: id,
      problemSlug: slug,
      card: Map<String, Object?>.from(json['card'] as Map),
      logs: (json['logs'] as List? ?? const [])
          .map(
            (value) =>
                ReviewEvent.fromJson(Map<String, Object?>.from(value as Map)),
          )
          .toList(),
      nextDueUtc: _utc(json['nextDueUtc']),
      lastReviewUtc: json['lastReviewUtc'] == null
          ? null
          : _utc(json['lastReviewUtc']),
      state: json['state'] as String,
      stability: (json['stability'] as num?)?.toDouble(),
      difficulty: (json['difficulty'] as num?)?.toDouble(),
      retrievability: (json['retrievability'] as num?)?.toDouble(),
      createdAtUtc: _utc(json['createdAtUtc']),
      updatedAtUtc: _utc(json['updatedAtUtc']),
      schemaVersion: json['schemaVersion'] as int? ?? 1,
    );
  }

  final int schemaVersion;
  final String id;
  final String problemSlug;
  final Map<String, Object?> card;
  final List<ReviewEvent> logs;
  final DateTime nextDueUtc;
  final DateTime? lastReviewUtc;
  final String state;
  final double? stability;
  final double? difficulty;
  final double? retrievability;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  ReviewRecord copyWith({
    Map<String, Object?>? card,
    List<ReviewEvent>? logs,
    DateTime? nextDueUtc,
    DateTime? lastReviewUtc,
    String? state,
    double? stability,
    double? difficulty,
    double? retrievability,
    DateTime? updatedAtUtc,
  }) => ReviewRecord(
    schemaVersion: schemaVersion,
    id: id,
    problemSlug: problemSlug,
    card: card ?? this.card,
    logs: logs ?? this.logs,
    nextDueUtc: (nextDueUtc ?? this.nextDueUtc).toUtc(),
    lastReviewUtc: lastReviewUtc ?? this.lastReviewUtc,
    state: state ?? this.state,
    stability: stability ?? this.stability,
    difficulty: difficulty ?? this.difficulty,
    retrievability: retrievability ?? this.retrievability,
    createdAtUtc: createdAtUtc,
    updatedAtUtc: (updatedAtUtc ?? this.updatedAtUtc).toUtc(),
  );

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'problemSlug': problemSlug,
    'card': card,
    'logs': logs.map((value) => value.toJson()).toList(),
    'nextDueUtc': nextDueUtc.toUtc().toIso8601String(),
    'lastReviewUtc': lastReviewUtc?.toUtc().toIso8601String(),
    'state': state,
    'stability': stability,
    'difficulty': difficulty,
    'retrievability': retrievability,
    'createdAtUtc': createdAtUtc.toUtc().toIso8601String(),
    'updatedAtUtc': updatedAtUtc.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is ReviewRecord && _jsonEqual(toJson(), other.toJson());

  @override
  int get hashCode => Object.hash(id, problemSlug, updatedAtUtc);
}

DateTime _utc(Object? value) => DateTime.parse(value as String).toUtc();

void _validateSlug(String value) {
  if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(value)) {
    throw const FormatException('Invalid problem slug');
  }
}

void _validateId(String value) {
  if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(value)) {
    throw const FormatException('Invalid stable ID');
  }
}

bool _jsonEqual(Object? left, Object? right) {
  if (left is Map && right is Map) {
    return left.length == right.length &&
        left.entries.every(
          (entry) => _jsonEqual(entry.value, right[entry.key]),
        );
  }
  if (left is List && right is List) {
    return left.length == right.length &&
        left.indexed.every((item) => _jsonEqual(item.$2, right[item.$1]));
  }
  return left == right;
}
