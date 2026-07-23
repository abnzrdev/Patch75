import 'dart:convert';

enum JudgeMode { scratch, tests, submit }

class JudgeRequest {
  const JudgeRequest({
    required this.problemSlug,
    required this.language,
    required this.sourceCode,
    required this.selectedTests,
    this.mode = JudgeMode.tests,
  });

  static const maxSourceBytes = 64 * 1024;
  static const _languages = {'python'};

  final String problemSlug;
  final String language;
  final String sourceCode;
  final List<String> selectedTests;
  final JudgeMode mode;

  bool get submit => mode == JudgeMode.submit;

  void validate() {
    if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(problemSlug)) {
      throw ArgumentError.value(problemSlug, 'problemSlug');
    }
    if (!_languages.contains(language)) {
      throw ArgumentError.value(language, 'language');
    }
    if (utf8.encode(sourceCode).length > maxSourceBytes) {
      throw ArgumentError('Source exceeds $maxSourceBytes bytes');
    }
  }
}

enum JudgeStatus { passed, failed, timeout, error, unavailable }

class JudgeTestInput {
  const JudgeTestInput({required this.id, required this.values});

  final String id;
  final Map<String, Object?> values;

  Map<String, Object?> toJson() => {'id': id, ...values};
}

class JudgeTestResult {
  const JudgeTestResult({
    required this.id,
    required this.passed,
    required this.output,
    required this.expected,
    required this.error,
  });

  factory JudgeTestResult.fromJson(Map<String, Object?> json) =>
      JudgeTestResult(
        id: json['id'] as String,
        passed: json['passed'] as bool,
        output: json['output'] as String? ?? '',
        expected: json['expected'] as String? ?? '',
        error: json['error'] as String?,
      );

  final String id;
  final bool passed;
  final String output;
  final String expected;
  final String? error;
}

class JudgeResult {
  const JudgeResult({
    required this.status,
    required this.stdout,
    required this.stderr,
    required this.executionTimeMs,
    required this.memoryUsageBytes,
    required this.passedTests,
    required this.totalTests,
    required this.testResults,
  });

  factory JudgeResult.fromJson(Map<String, Object?> json) => JudgeResult(
    status: JudgeStatus.values.byName(json['status'] as String),
    stdout: json['stdout'] as String? ?? '',
    stderr: json['stderr'] as String? ?? '',
    executionTimeMs: json['executionTimeMs'] as int? ?? 0,
    memoryUsageBytes: json['memoryUsageBytes'] as int?,
    passedTests: json['passedTests'] as int? ?? 0,
    totalTests: json['totalTests'] as int? ?? 0,
    testResults: (json['testResults'] as List? ?? const [])
        .map((value) => JudgeTestResult.fromJson(value as Map<String, Object?>))
        .toList(),
  );

  final JudgeStatus status;
  final String stdout;
  final String stderr;
  final int executionTimeMs;
  final int? memoryUsageBytes;
  final int passedTests;
  final int totalTests;
  final List<JudgeTestResult> testResults;
}

String truncateOutput(String value, int maxBytes) {
  final bytes = utf8.encode(value);
  if (bytes.length <= maxBytes) return value;
  var end = maxBytes;
  while (end > 0) {
    try {
      return utf8.decode(bytes.sublist(0, end));
    } on FormatException {
      end--;
    }
  }
  return '';
}
