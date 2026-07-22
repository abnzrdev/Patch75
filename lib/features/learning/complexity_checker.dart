enum ComplexityStatus { correct, partiallyCorrect, different }

class ComplexityComparison {
  const ComplexityComparison({required this.status, required this.explanation});

  final ComplexityStatus status;
  final String explanation;
}

String normalizeComplexity(String value) {
  var normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll('×', '*')
      .replaceAll('⋅', '*')
      .replaceAll('^2', '²')
      .replaceAll('^3', '³')
      .replaceAll('*', '·');
  if (normalized.startsWith('o(')) {
    normalized = 'O(${normalized.substring(2)}';
  }
  return normalized;
}

ComplexityComparison compareComplexity(
  String enteredTime,
  String expectedTime,
  String enteredSpace,
  String expectedSpace,
) {
  final timeMatches =
      normalizeComplexity(enteredTime) == normalizeComplexity(expectedTime);
  final spaceMatches =
      normalizeComplexity(enteredSpace) == normalizeComplexity(expectedSpace);
  if (timeMatches && spaceMatches) {
    return const ComplexityComparison(
      status: ComplexityStatus.correct,
      explanation: 'Both time and space match the expected analysis.',
    );
  }
  if (timeMatches || spaceMatches) {
    return ComplexityComparison(
      status: ComplexityStatus.partiallyCorrect,
      explanation: timeMatches
          ? 'Time matches; revisit the auxiliary-space analysis.'
          : 'Space matches; revisit the operation count.',
    );
  }
  return const ComplexityComparison(
    status: ComplexityStatus.different,
    explanation: 'Both answers differ from the checked-in expected analysis.',
  );
}
