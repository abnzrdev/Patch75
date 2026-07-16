import 'dart:convert';

class JudgeRequest {
  const JudgeRequest({
    required this.problemSlug,
    required this.language,
    required this.sourceCode,
    required this.selectedTests,
  });

  static const maxSourceBytes = 64 * 1024;
  static const _languages = {'python'};

  final String problemSlug;
  final String language;
  final String sourceCode;
  final List<String> selectedTests;

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
