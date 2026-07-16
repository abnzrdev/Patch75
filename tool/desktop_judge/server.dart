import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:offline_leetcode_trainer/features/judge/desktop_docker_runner.dart';
import 'package:offline_leetcode_trainer/features/judge/judge_models.dart';

const _maxBodyBytes = 256 * 1024;
const _maxOutputBytes = 256 * 1024;

Future<void> main(List<String> args) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 5376);
  stdout.writeln('Offline judge listening on http://127.0.0.1:5376');
  await for (final request in server) {
    unawaited(_handle(request));
  }
}

Future<void> _handle(HttpRequest request) async {
  request.response.headers.contentType = ContentType.json;
  try {
    if (request.method == 'GET' && request.uri.path == '/health') {
      request.response.write('{"status":"ok"}');
    } else if (request.method == 'POST' && request.uri.path == '/judge') {
      final declared = request.contentLength;
      if (declared > _maxBodyBytes) {
        throw const FormatException('Request body too large');
      }
      final body = await _readBounded(request, _maxBodyBytes);
      final json = jsonDecode(utf8.decode(body)) as Map<String, Object?>;
      final result = await _judge(json);
      request.response.write(jsonEncode(result));
    } else {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('{"error":"Not found"}');
    }
  } on FormatException catch (error) {
    request.response.statusCode = HttpStatus.badRequest;
    request.response.write(jsonEncode({'error': error.message}));
  } on Object catch (error) {
    request.response.statusCode = HttpStatus.internalServerError;
    request.response.write(jsonEncode({'error': 'Judge failure: $error'}));
  } finally {
    await request.response.close();
  }
}

Future<Map<String, Object?>> _judge(Map<String, Object?> json) async {
  final request = JudgeRequest(
    problemSlug: json['problemSlug'] as String? ?? '',
    language: json['language'] as String? ?? '',
    sourceCode: json['sourceCode'] as String? ?? '',
    selectedTests: List<String>.from(
      json['selectedTests'] as List? ?? const [],
    ),
  );
  request.validate();
  if (request.problemSlug != 'two-sum') {
    throw const FormatException('Problem is not installed');
  }
  final selected = request.selectedTests.toSet();
  final tests = (json['tests'] as List? ?? const [])
      .map((value) => _test(value as Map<String, Object?>))
      .where((test) => selected.isEmpty || selected.contains(test.id))
      .toList();
  if (tests.isEmpty || tests.length > 100) {
    throw const FormatException('Select between 1 and 100 tests');
  }

  final name =
      'olt-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${Random.secure().nextInt(0xffffff).toRadixString(16)}';
  final started = Stopwatch()..start();
  Process? process;
  try {
    process = await Process.start('docker', dockerArguments(name));
    process.stdin
      ..write(dockerPayload(request, tests))
      ..close();
    final outputs = await Future.wait([
      _collect(process.stdout, process),
      _collect(process.stderr, process),
      process.exitCode
          .timeout(
            const Duration(seconds: 6),
            onTimeout: () {
              process!.kill(ProcessSignal.sigkill);
              return 124;
            },
          )
          .then((code) => utf8.encode(code.toString())),
    ]);
    final exitCode = int.parse(utf8.decode(outputs[2]));
    final stdoutText = utf8.decode(outputs[0]).trim();
    final stderrText = utf8.decode(outputs[1]).trim();
    if (exitCode == 124 || exitCode == 137) {
      return _failure(
        'timeout',
        'Time Limit Exceeded',
        started.elapsedMilliseconds,
        tests.length,
      );
    }
    if (exitCode != 0) {
      return _failure(
        'error',
        stderrText,
        started.elapsedMilliseconds,
        tests.length,
      );
    }
    final result = jsonDecode(stdoutText) as Map<String, Object?>;
    result['executionTimeMs'] = started.elapsedMilliseconds;
    return result;
  } on ProcessException catch (error) {
    return _failure(
      'unavailable',
      error.message,
      started.elapsedMilliseconds,
      tests.length,
    );
  } finally {
    process?.kill();
    await Process.run('docker', ['rm', '-f', name]);
  }
}

JudgeTestInput _test(Map<String, Object?> json) {
  final id = json['id'] as String? ?? '';
  final nums = json['nums'] as List? ?? const [];
  final target = json['target'];
  if (!RegExp(r'^[a-z0-9-]{1,64}$').hasMatch(id) ||
      nums.length > 10000 ||
      nums.any((value) => value is! int) ||
      target is! int) {
    throw const FormatException('Invalid test input');
  }
  return JudgeTestInput(
    id: id,
    values: {'nums': List<int>.from(nums), 'target': target},
  );
}

Future<List<int>> _readBounded(Stream<List<int>> stream, int limit) async {
  final bytes = <int>[];
  await for (final chunk in stream) {
    bytes.addAll(chunk);
    if (bytes.length > limit) throw const FormatException('Payload too large');
  }
  return bytes;
}

Future<List<int>> _collect(Stream<List<int>> stream, Process process) async {
  final bytes = <int>[];
  await for (final chunk in stream) {
    bytes.addAll(chunk);
    if (bytes.length > _maxOutputBytes) {
      process.kill(ProcessSignal.sigkill);
      throw const FormatException('Judge output too large');
    }
  }
  return bytes;
}

Map<String, Object?> _failure(
  String status,
  String error,
  int elapsed,
  int total,
) => {
  'status': status,
  'stdout': '',
  'stderr': truncateOutput(error, 65536),
  'executionTimeMs': elapsed,
  'memoryUsageBytes': null,
  'passedTests': 0,
  'totalTests': total,
  'testResults': <Object?>[],
};
