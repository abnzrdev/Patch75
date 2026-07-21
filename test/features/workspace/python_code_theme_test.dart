import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/workspace/python_code_theme.dart';

void main() {
  test('highlights all required Python token categories', () {
    const source = '''
class Solver:
    def solve(self, values: List[int]) -> int:
        # add a value
        answer = 42 + len("lime")
        return answer
''';
    final tokens = <String, TextStyle?>{};

    void collect(InlineSpan span) {
      if (span is! TextSpan) return;
      if (span.text case final text?) tokens[text] = span.style;
      for (final child in span.children ?? const <InlineSpan>[]) {
        collect(child);
      }
    }

    collect(highlightPython(source));

    TextStyle? styleContaining(String value) =>
        tokens.entries.firstWhere((entry) => entry.key.contains(value)).value;

    expect(styleContaining('class'), pythonHighlightStyles['keyword']);
    expect(styleContaining('Solver'), pythonHighlightStyles['title.class']);
    expect(styleContaining('solve'), pythonHighlightStyles['title.function']);
    expect(styleContaining('List'), pythonHighlightStyles['type']);
    expect(styleContaining('"lime"'), pythonHighlightStyles['string']);
    expect(styleContaining('42'), pythonHighlightStyles['number']);
    expect(styleContaining('# add'), pythonHighlightStyles['comment']);
    expect(styleContaining('+'), pythonHighlightStyles['operator']);
  });
}
