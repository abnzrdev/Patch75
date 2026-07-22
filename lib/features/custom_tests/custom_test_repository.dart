import 'dart:convert';

import 'custom_test_case.dart';

abstract interface class CustomTestRepository {
  String? validate(CustomTestCase value);
  Map<String, Object?> parseAdvancedJson(String source);
  List<CustomTestCase> save(List<CustomTestCase> values, CustomTestCase value);
  List<CustomTestCase> delete(List<CustomTestCase> values, String id);
  List<CustomTestCase> duplicate(
    List<CustomTestCase> values,
    String id, {
    required DateTime nowUtc,
  });
  List<CustomTestCase> toggle(
    List<CustomTestCase> values,
    String id,
    bool enabled, {
    required DateTime nowUtc,
  });
  List<CustomTestCase> reorder(
    List<CustomTestCase> values,
    int oldIndex,
    int newIndex,
  );
}

class LocalCustomTestRepository implements CustomTestRepository {
  const LocalCustomTestRepository({
    required this.requiredFields,
    this.maxTests = 50,
    this.maxInputBytes = 32 * 1024,
  });

  final Map<String, Type> requiredFields;
  final int maxTests;
  final int maxInputBytes;

  @override
  String? validate(CustomTestCase value) {
    if (value.name.trim().isEmpty || value.name.length > 80) {
      return 'Name must be between 1 and 80 characters.';
    }
    if (utf8.encode(jsonEncode(value.input)).length > maxInputBytes) {
      return 'Input exceeds $maxInputBytes bytes.';
    }
    for (final entry in requiredFields.entries) {
      if (!value.input.containsKey(entry.key)) {
        return '${entry.key} is required.';
      }
      final actual = value.input[entry.key];
      if (!_matches(actual, entry.value)) {
        return '${entry.key} must be ${entry.value}.';
      }
    }
    return null;
  }

  @override
  Map<String, Object?> parseAdvancedJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Custom input must be a JSON object.');
    }
    return Map<String, Object?>.from(decoded);
  }

  @override
  List<CustomTestCase> save(List<CustomTestCase> values, CustomTestCase value) {
    final error = validate(value);
    if (error != null) throw FormatException(error);
    final index = values.indexWhere((item) => item.id == value.id);
    if (index < 0 && values.length >= maxTests) {
      throw StateError('Maximum of $maxTests custom tests reached.');
    }
    return [
      for (final item in values)
        if (item.id == value.id) value else item,
      if (index < 0) value,
    ];
  }

  @override
  List<CustomTestCase> delete(List<CustomTestCase> values, String id) =>
      values.where((item) => item.id != id).toList();

  @override
  List<CustomTestCase> duplicate(
    List<CustomTestCase> values,
    String id, {
    required DateTime nowUtc,
  }) {
    if (values.length >= maxTests) {
      throw StateError('Maximum of $maxTests custom tests reached.');
    }
    final source = values.firstWhere((item) => item.id == id);
    final now = nowUtc.toUtc();
    return [
      ...values,
      CustomTestCase.create(
        id: 'custom-${source.problemSlug}-${now.microsecondsSinceEpoch}',
        problemSlug: source.problemSlug,
        name: '${source.name} copy',
        input: Map<String, Object?>.from(source.input),
        nowUtc: now,
      ),
    ];
  }

  @override
  List<CustomTestCase> toggle(
    List<CustomTestCase> values,
    String id,
    bool enabled, {
    required DateTime nowUtc,
  }) => [
    for (final item in values)
      if (item.id == id)
        item.copyWith(enabled: enabled, updatedAtUtc: nowUtc)
      else
        item,
  ];

  @override
  List<CustomTestCase> reorder(
    List<CustomTestCase> values,
    int oldIndex,
    int newIndex,
  ) {
    final reordered = [...values];
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);
    return reordered;
  }
}

bool _matches(Object? value, Type type) => type == int
    ? value is int
    : type == double
    ? value is num
    : type == String
    ? value is String
    : type == bool
    ? value is bool
    : type == List
    ? value is List
    : type == Map
    ? value is Map
    : false;
