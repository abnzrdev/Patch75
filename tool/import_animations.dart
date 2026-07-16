import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final source = Directory(
    args.isEmpty ? '.cache/external/LeetCodeAnimation' : args.first,
  );
  final manifestFile = File('${source.path}/docs/data/manifest.json');
  if (!manifestFile.existsSync()) {
    stderr.writeln(
      'LeetCodeAnimation manifest not found: ${manifestFile.path}',
    );
    exitCode = 2;
    return;
  }
  final manifest = jsonDecode(manifestFile.readAsStringSync()) as List;
  final bySlug = {
    for (final raw in manifest)
      (raw as Map<String, Object?>)['slug'] as String: raw,
  };
  final blind =
      jsonDecode(File('assets/data/index/blind75.json').readAsStringSync())
          as Map<String, Object?>;
  final entries = [
    for (final raw in blind['problems'] as List)
      _entry(raw as Map<String, Object?>, bySlug[raw['slug']]),
  ];
  const encoder = JsonEncoder.withIndent('  ');
  final output = File('assets/data/animation_index.json')
    ..writeAsStringSync('${encoder.convert(entries)}\n');
  final matched = entries.where((entry) => entry['problemId'] != 0).length;
  stdout.writeln(
    'Wrote ${output.path}: $matched manifest matches; media omitted (no upstream license)',
  );
}

Map<String, Object?> _entry(
  Map<String, Object?> problem,
  Map<String, Object?>? animation,
) => {
  'problemId': animation?['leetcodeId'] as int? ?? 0,
  'slug': problem['slug'],
  'title': problem['title'],
  'relativePath': null,
  'sourceRelativePath': animation?['gifPath'],
  'sourceUrl':
      animation?['siteUrl'] ??
      'https://github.com/MisterBooo/LeetCodeAnimation',
  'status': animation == null ? 'not-found' : 'local-import-required',
};
