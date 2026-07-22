class CustomTestCase {
  const CustomTestCase({
    required this.id,
    required this.problemSlug,
    required this.name,
    required this.input,
    required this.enabled,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.schemaVersion = 1,
  });

  factory CustomTestCase.create({
    required String id,
    required String problemSlug,
    required String name,
    required Map<String, Object?> input,
    required DateTime nowUtc,
  }) {
    _validateId(id);
    _validateSlug(problemSlug);
    final now = nowUtc.toUtc();
    return CustomTestCase(
      id: id,
      problemSlug: problemSlug,
      name: name,
      input: input,
      enabled: true,
      createdAtUtc: now,
      updatedAtUtc: now,
    );
  }

  factory CustomTestCase.fromJson(Map<String, Object?> json) {
    final id = json['id'] as String;
    final slug = json['problemSlug'] as String;
    _validateId(id);
    _validateSlug(slug);
    return CustomTestCase(
      id: id,
      problemSlug: slug,
      name: json['name'] as String,
      input: Map<String, Object?>.from(json['input'] as Map),
      enabled: json['enabled'] as bool? ?? true,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String).toUtc(),
      updatedAtUtc: DateTime.parse(json['updatedAtUtc'] as String).toUtc(),
      schemaVersion: json['schemaVersion'] as int? ?? 1,
    );
  }

  final int schemaVersion;
  final String id;
  final String problemSlug;
  final String name;
  final Map<String, Object?> input;
  final bool enabled;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  CustomTestCase copyWith({
    String? id,
    String? name,
    Map<String, Object?>? input,
    bool? enabled,
    DateTime? updatedAtUtc,
  }) => CustomTestCase(
    schemaVersion: schemaVersion,
    id: id ?? this.id,
    problemSlug: problemSlug,
    name: name ?? this.name,
    input: input ?? this.input,
    enabled: enabled ?? this.enabled,
    createdAtUtc: createdAtUtc,
    updatedAtUtc: (updatedAtUtc ?? this.updatedAtUtc).toUtc(),
  );

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'problemSlug': problemSlug,
    'name': name,
    'input': input,
    'enabled': enabled,
    'createdAtUtc': createdAtUtc.toUtc().toIso8601String(),
    'updatedAtUtc': updatedAtUtc.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is CustomTestCase &&
      id == other.id &&
      problemSlug == other.problemSlug &&
      name == other.name &&
      enabled == other.enabled &&
      createdAtUtc == other.createdAtUtc &&
      updatedAtUtc == other.updatedAtUtc &&
      _mapEqual(input, other.input);

  @override
  int get hashCode => Object.hash(id, problemSlug, updatedAtUtc);
}

void _validateId(String value) {
  if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(value)) {
    throw ArgumentError.value(value, 'id');
  }
}

void _validateSlug(String value) {
  if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(value)) {
    throw ArgumentError.value(value, 'problemSlug');
  }
}

bool _mapEqual(Map<String, Object?> left, Map<String, Object?> right) =>
    left.length == right.length &&
    left.entries.every((entry) => '${entry.value}' == '${right[entry.key]}');
