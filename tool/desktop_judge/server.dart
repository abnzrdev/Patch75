import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:offline_leetcode_trainer/features/judge/desktop_docker_runner.dart';
import 'package:offline_leetcode_trainer/features/judge/judge_models.dart';

const _maxRequestBytes = 256 * 1024;

Future<void> main(List<String> args) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 5376);
  stdout.writeln('Offline Docker bridge listening on http://127.0.0.1:5376');
  await for (final request in server) {
    unawaited(_handle(request));
  }
}

Future<void> _handle(HttpRequest request) async {
  request.response.headers.contentType = ContentType.json;
  try {
    if (request.method == 'GET' && request.uri.path == '/health') {
      request.response.write(
        jsonEncode({
          'status': 'ok',
          'backend': 'docker',
          'capabilities': ['scratch'],
        }),
      );
      return;
    }
    if (request.method == 'POST' && request.uri.path == '/judge') {
      final decoded = jsonDecode(
        utf8.decode(await _readBounded(request, _maxRequestBytes)),
      );
      if (decoded is! Map) {
        throw const FormatException('Request must be a JSON object');
      }
      request.response.write(
        jsonEncode(await _judge(Map<String, Object?>.from(decoded))),
      );
      return;
    }
    request.response.statusCode = HttpStatus.notFound;
    request.response.write(jsonEncode({'error': 'Not found'}));
  } on FormatException catch (error) {
    request.response.statusCode = HttpStatus.badRequest;
    request.response.write(jsonEncode({'error': error.message}));
  } on Object catch (error, stackTrace) {
    stderr.writeln('Bridge failure: $error\n$stackTrace');
    request.response.statusCode = HttpStatus.internalServerError;
    request.response.write(jsonEncode({'error': 'Bridge failure'}));
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
    mode: JudgeMode.values.byName(json['mode'] as String? ?? 'tests'),
  );
  request.validate();
  if (request.language != 'python' || request.mode != JudgeMode.scratch) {
    throw const FormatException('Only Python scratch execution is enabled');
  }

  final name = 'patch75-run-${DateTime.now().microsecondsSinceEpoch}';
  final process = await Process.start('docker', dockerArguments(name));
  process.stdin.write(dockerPayload(request, const []));
  await process.stdin.close();
  try {
    final values = await Future.wait<Object>([
      _readBounded(process.stdout, _maxRequestBytes),
      _readBounded(process.stderr, _maxRequestBytes),
      process.exitCode,
    ]).timeout(const Duration(seconds: 10));
    final output = utf8.decode(values[0] as List<int>, allowMalformed: true);
    final error = utf8.decode(values[1] as List<int>, allowMalformed: true);
    if (values[2] != 0) {
      throw StateError(error.isEmpty ? 'Docker execution failed' : error);
    }
    return Map<String, Object?>.from(jsonDecode(output) as Map);
  } on Object {
    process.kill();
    await Process.run('docker', ['kill', name]).timeout(
      const Duration(seconds: 3),
      onTimeout: () => ProcessResult(0, -1, '', 'Docker cleanup timed out'),
    );
    rethrow;
  }
}

Future<List<int>> _readBounded(Stream<List<int>> stream, int limit) async {
  final bytes = <int>[];
  await for (final chunk in stream) {
    bytes.addAll(chunk);
    if (bytes.length > limit) {
      throw const FormatException('Payload exceeds allowed size');
    }
  }
  return bytes;
}
