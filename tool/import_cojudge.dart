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

  final problemDir = Directory('${source.path}/problems/two-sum');
  final result = normalizeCojudgeProblem(
    slug: 'two-sum',
    statement: File('${problemDir.path}/statement.md').readAsStringSync(),
    metadata:
        jsonDecode(File('${problemDir.path}/metadata.json').readAsStringSync())
            as Map<String, Object?>,
    tests:
        jsonDecode(
              File('${problemDir.path}/official-tests.json').readAsStringSync(),
            )
            as List<Object?>,
  );
  const encoder = JsonEncoder.withIndent('  ');
  final output = File('assets/data/problems/two-sum.json')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('${encoder.convert(result)}\n');
  final index = File('assets/data/index/blind75.json')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(
      '${encoder.convert({
        'version': 1,
        'sourceRevision': _revision(source),
        'problems': [
          {'id': result['id'], 'slug': result['slug'], 'title': result['title'], 'difficulty': result['difficulty'], 'topics': result['topics']},
        ],
      })}\n',
    );
  stdout.writeln('Wrote ${output.path} and ${index.path}');
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
