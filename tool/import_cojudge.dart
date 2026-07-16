import 'dart:convert';
import 'dart:io';

import 'package:offline_leetcode_trainer/features/problems/cojudge_importer.dart';

void main(List<String> args) {
  final source = Directory(
    args.isEmpty ? '.cache/external/cojudge' : args.first,
  );
  if (!source.existsSync()) {
    stderr.writeln('cojudge checkout not found: ${source.path}');
    exitCode = 2;
    return;
  }

  const encoder = JsonEncoder.withIndent('  ');
  final course =
      jsonDecode(
            File(
              '${source.path}/courses/blind75/courseinfo.json',
            ).readAsStringSync(),
          )
          as Map<String, Object?>;
  final categories = course['problems-of-category'] as Map<String, Object?>;
  final results = <Map<String, Object?>>[];
  for (final entry in categories.entries) {
    for (final slug in List<String>.from(entry.value as List)) {
      final problemDir = Directory('${source.path}/problems/$slug');
      final result = normalizeCojudgeProblem(
        slug: slug,
        statement: File('${problemDir.path}/statement.md').readAsStringSync(),
        metadata:
            jsonDecode(
                  File('${problemDir.path}/metadata.json').readAsStringSync(),
                )
                as Map<String, Object?>,
        tests:
            jsonDecode(
                  File(
                    '${problemDir.path}/official-tests.json',
                  ).readAsStringSync(),
                )
                as List<Object?>,
      );
      results.add(result);
      final output = File('assets/data/problems/$slug.json')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('${encoder.convert(result)}\n');
      stdout.writeln('Wrote ${output.path}');
    }
  }
  final index = File('assets/data/index/blind75.json')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(
      '${encoder.convert({
        'version': 1,
        'sourceRevision': _revision(source),
        'problems': [
          for (final result in results) {'id': result['id'], 'slug': result['slug'], 'title': result['title'], 'difficulty': result['difficulty'], 'topics': result['topics']},
        ],
      })}\n',
    );
  stdout.writeln('Wrote ${results.length} problems and ${index.path}');
}

String _revision(Directory source) {
  final result = Process.runSync('git', [
    '-C',
    source.path,
    'rev-parse',
    'HEAD',
  ]);
  if (result.exitCode != 0) throw StateError('Cannot read source revision');
  return (result.stdout as String).trim();
}
