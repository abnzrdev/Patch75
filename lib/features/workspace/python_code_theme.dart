import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/re_highlight.dart';

import '../../core/design/olt_design.dart';

final _pythonMode = Mode(
  refs: langPython.refs,
  name: langPython.name,
  aliases: langPython.aliases,
  unicodeRegex: langPython.unicodeRegex,
  keywords: langPython.keywords,
  illegal: langPython.illegal,
  contains: <Mode>[
    ...(langPython.contains as List<Mode>),
    Mode(
      scope: 'operator',
      match: r'//|\*\*|:=|==|!=|<=|>=|->|[-+*/%@&|^~<>]=?',
    ),
  ],
);

const pythonHighlightStyles = <String, TextStyle>{
  'keyword': TextStyle(color: Color(0xFFB7FF3C), fontWeight: FontWeight.w700),
  'title.class': TextStyle(color: Color(0xFFFFD166)),
  'title.function': TextStyle(color: Color(0xFF7FDBFF)),
  'type': TextStyle(color: Color(0xFFFF9F68)),
  'built_in': TextStyle(color: Color(0xFFFF9F68)),
  'string': TextStyle(color: Color(0xFFA8D08D)),
  'number': TextStyle(color: Color(0xFFC9A7FF)),
  'comment': TextStyle(color: OltColors.muted, fontStyle: FontStyle.italic),
  'operator': TextStyle(color: Color(0xFFFF7A90)),
  'literal': TextStyle(color: Color(0xFFC9A7FF)),
  'meta': TextStyle(color: OltColors.muted),
};

final pythonCodeTheme = CodeHighlightTheme(
  languages: {'python': CodeHighlightThemeMode(mode: _pythonMode)},
  theme: pythonHighlightStyles,
);

TextSpan highlightPython(String source) {
  final highlighter = Highlight()..registerLanguage('python', _pythonMode);
  final result = highlighter.highlight(code: source, language: 'python');
  final renderer = TextSpanRenderer(null, pythonHighlightStyles);
  result.render(renderer);
  return renderer.span ?? TextSpan(text: source);
}
