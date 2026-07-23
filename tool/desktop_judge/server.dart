import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:offline_leetcode_trainer/features/judge/judge_models.dart';
import 'package:offline_leetcode_trainer/features/judge/desktop_docker_runner.dart';

const _maxRequestBytes = 256 * 1024;
const _maxBackendBytes = 2 * 1024 * 1024;

final _cojudgePort =
    int.tryParse(Platform.environment['COJUDGE_PORT'] ?? '') ?? 5375;

final _cojudgeRoot = Directory(
  Platform.environment['COJUDGE_DIR'] ??
      '${Directory.current.path}/.cache/external/cojudge',
);

final _cojudgeBase = Uri.parse('http://127.0.0.1:$_cojudgePort/');

final HttpClient _backendClient = HttpClient()
  ..findProxy = ((_) => 'DIRECT')
  ..connectionTimeout = const Duration(seconds: 5);

Future<void> main(List<String> args) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 5376);

  stdout.writeln('Offline Cojudge bridge listening on http://127.0.0.1:5376');

  await for (final request in server) {
    unawaited(_handle(request));
  }
}

Future<void> _handle(HttpRequest request) async {
  request.response.headers.contentType = ContentType.json;

  try {
    if (request.method == 'GET' && request.uri.path == '/health') {
      final available = await _cojudgeAvailable();

      request.response.statusCode = available
          ? HttpStatus.ok
          : HttpStatus.serviceUnavailable;

      request.response.write(
        jsonEncode({
          'status': available ? 'ok' : 'unavailable',
          'backend': 'cojudge',
        }),
      );
      return;
    }

    if (request.method == 'POST' && request.uri.path == '/judge') {
      final bytes = await _readBounded(request, _maxRequestBytes);
      final decoded = jsonDecode(utf8.decode(bytes));

      if (decoded is! Map) {
        throw const FormatException('Request must be a JSON object');
      }

      final result = await _judge(Map<String, Object?>.from(decoded));
      request.response.write(jsonEncode(result));
      return;
    }

    request.response.statusCode = HttpStatus.notFound;
    request.response.write(jsonEncode({'error': 'Not found'}));
  } on FormatException catch (error) {
    request.response.statusCode = HttpStatus.badRequest;
    request.response.write(jsonEncode({'error': error.message}));
  } on Object catch (error, stackTrace) {
    stderr.writeln('Bridge failure: $error');
    stderr.writeln(stackTrace);

    request.response.statusCode = HttpStatus.internalServerError;
    request.response.write(jsonEncode({'error': 'Bridge failure: $error'}));
  } finally {
    await request.response.close();
  }
}

Future<bool> _cojudgeAvailable() async {
  try {
    if (!_cojudgeRoot.existsSync()) return false;

    final response = await _backendRequest(
      'GET',
      '/api/image/status?language=python',
    ).timeout(const Duration(seconds: 5));

    return response.statusCode == HttpStatus.ok;
  } on Object {
    return false;
  }
}

Future<Map<String, Object?>> _judge(Map<String, Object?> json) async {
  final started = Stopwatch()..start();

  final request = JudgeRequest(
    problemSlug: json['problemSlug'] as String? ?? '',
    language: json['language'] as String? ?? '',
    sourceCode: json['sourceCode'] as String? ?? '',
    selectedTests: List<String>.from(
      json['selectedTests'] as List? ?? const [],
    ),
    mode: JudgeMode.values.byName(json['mode'] as String? ?? 'tests'),
  );

  try {
    request.validate();

    if (request.language != 'python') {
      return _failure(
        status: 'error',
        message: 'Cojudge bridge currently accepts Python submissions.',
        elapsedMs: started.elapsedMilliseconds,
        totalTests: request.selectedTests.length,
      );
    }

    if (request.mode == JudgeMode.scratch) {
      return await _runScratch(request);
    }

    final problemDirectory = Directory(
      '${_cojudgeRoot.path}/problems/${request.problemSlug}',
    );

    if (!problemDirectory.existsSync()) {
      return _failure(
        status: 'error',
        message:
            'Problem "${request.problemSlug}" is not installed in Cojudge.',
        elapsedMs: started.elapsedMilliseconds,
        totalTests: request.selectedTests.length,
      );
    }

    if (request.submit) {
      return await _submit(request, started);
    }

    return await _runSamples(request, started);
  } on TimeoutException catch (error) {
    return _failure(
      status: 'timeout',
      message: 'Time Limit Exceeded: $error',
      elapsedMs: started.elapsedMilliseconds,
      totalTests: request.selectedTests.length,
    );
  } on _BackendException catch (error) {
    return _failure(
      status: 'error',
      message: error.message,
      elapsedMs: started.elapsedMilliseconds,
      totalTests: request.selectedTests.length,
    );
  } on Object catch (error, stackTrace) {
    stderr.writeln('Judge error for ${request.problemSlug}: $error');
    stderr.writeln(stackTrace);

    return _failure(
      status: 'error',
      message: 'Cojudge execution failed: $error',
      elapsedMs: started.elapsedMilliseconds,
      totalTests: request.selectedTests.length,
    );
  }
}

Future<Map<String, Object?>> _runScratch(JudgeRequest request) async {
  final name = 'olt-run-${DateTime.now().microsecondsSinceEpoch}';
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
    final exitCode = values[2] as int;
    if (exitCode != 0) {
      throw StateError(error.isEmpty ? 'Docker exited $exitCode' : error);
    }
    return Map<String, Object?>.from(jsonDecode(output) as Map);
  } on Object {
    process.kill();
    rethrow;
  }
}

Future<Map<String, Object?>> _runSamples(
  JudgeRequest request,
  Stopwatch started,
) async {
  final metadataFile = File(
    '${_cojudgeRoot.path}/problems/${request.problemSlug}/metadata.json',
  );

  final metadataDecoded = jsonDecode(await metadataFile.readAsString());

  if (metadataDecoded is! Map) {
    throw const FormatException('Invalid Cojudge metadata');
  }

  final metadata = Map<String, Object?>.from(metadataDecoded);
  final testCases = List<Object?>.from(
    metadata['testCases'] as List? ?? const [],
  );

  if (testCases.isEmpty) {
    throw const FormatException('No sample tests found in Cojudge metadata');
  }

  final job = await _startAndPoll('/api/run', {
    'problemId': request.problemSlug,
    'language': 'python',
    'code': request.sourceCode,
    'testCases': testCases,
  });

  if (job['timeout'] == true) {
    return _failure(
      status: 'timeout',
      message: 'Time Limit Exceeded',
      elapsedMs: started.elapsedMilliseconds,
      totalTests: testCases.length,
    );
  }

  final results = _resultList(job['results']);

  return _convertResults(
    results: results,
    elapsedMs: started.elapsedMilliseconds,
    totalTests: results.length,
  );
}

Future<Map<String, Object?>> _submit(
  JudgeRequest request,
  Stopwatch started,
) async {
  final collected = <Map<String, Object?>>[];
  var startTest = 0;
  var totalTests = 0;
  var passedTests = 0;
  var failed = false;

  for (var batchNumber = 0; batchNumber < 500; batchNumber++) {
    final job = await _startAndPoll('/api/submit', {
      'problemId': request.problemSlug,
      'language': 'python',
      'code': request.sourceCode,
      'startTcNo': startTest,
    });

    if (job['timeout'] == true) {
      return _failure(
        status: 'timeout',
        message: 'Time Limit Exceeded',
        elapsedMs: started.elapsedMilliseconds,
        totalTests: totalTests,
      );
    }

    totalTests = _asInt(job['totalTc']) ?? totalTests;
    final batch = _resultList(job['results']);
    collected.addAll(batch);

    final failedIndex = batch.indexWhere(
      (result) => result['isCorrect'] != true,
    );

    if (failedIndex >= 0) {
      passedTests = startTest + failedIndex;
      failed = true;
      break;
    }

    startTest += batch.length;
    passedTests = startTest;

    if (job['allAccepted'] == true ||
        (totalTests > 0 && startTest >= totalTests)) {
      passedTests = totalTests;
      break;
    }

    if (batch.isEmpty) {
      throw const _BackendException('Cojudge returned an empty submit batch.');
    }
  }

  if (totalTests == 0) {
    totalTests = collected.length;
  }

  return _convertResults(
    results: collected,
    elapsedMs: started.elapsedMilliseconds,
    totalTests: totalTests,
    passedTestsOverride: passedTests,
    forceFailed: failed,
  );
}

Future<Map<String, Object?>> _startAndPoll(
  String endpoint,
  Map<String, Object?> payload,
) async {
  final created = await _backendRequest('POST', endpoint, body: payload);

  if (created.statusCode != HttpStatus.ok) {
    throw _BackendException(_backendError(created));
  }

  final createdJson = created.jsonObject();
  final jobId = createdJson['jobId'] as String?;

  if (jobId == null || jobId.isEmpty) {
    throw const _BackendException('Cojudge did not return a job ID.');
  }

  for (var attempt = 0; attempt < 1800; attempt++) {
    final polled = await _backendRequest(
      'GET',
      '$endpoint?jobId=${Uri.encodeQueryComponent(jobId)}',
    );

    final data = polled.jsonObject();

    if (polled.statusCode != HttpStatus.ok) {
      throw _BackendException(
        data['error']?.toString() ?? _backendError(polled),
      );
    }

    if (data['ready'] == true) {
      if (data['error'] != null) {
        throw _BackendException(data['error'].toString());
      }

      return data;
    }

    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  throw TimeoutException('Cojudge job did not finish in time');
}

Future<_BackendResponse> _backendRequest(
  String method,
  String path, {
  Map<String, Object?>? body,
}) async {
  final uri = _cojudgeBase.resolve(path);
  final request = await _backendClient.openUrl(method, uri);

  request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);

  if (body != null) {
    request.headers.contentType = ContentType.json;
    request.add(utf8.encode(jsonEncode(body)));
  }

  final response = await request.close();
  final bytes = await _readBounded(response, _maxBackendBytes);

  return _BackendResponse(
    response.statusCode,
    utf8.decode(bytes, allowMalformed: true),
  );
}

List<Map<String, Object?>> _resultList(Object? value) {
  if (value is! List) return const [];

  return value.whereType<Map>().map(Map<String, Object?>.from).toList();
}

Map<String, Object?> _convertResults({
  required List<Map<String, Object?>> results,
  required int elapsedMs,
  required int totalTests,
  int? passedTestsOverride,
  bool forceFailed = false,
}) {
  final passedFromResults = results
      .where((result) => result['isCorrect'] == true)
      .length;

  final passedTests = passedTestsOverride ?? passedFromResults;
  final passed = !forceFailed && totalTests > 0 && passedTests >= totalTests;

  final logs = <String>[];
  final errors = <String>[];
  final testResults = <Map<String, Object?>>[];

  for (var index = 0; index < results.length && index < 100; index++) {
    final result = results[index];
    final isCorrect = result['isCorrect'] == true;
    final log = result['logs']?.toString().trim() ?? '';
    final error = result['error']?.toString().trim() ?? '';

    if (log.isNotEmpty) logs.add(log);

    if (!isCorrect) {
      errors.add(error.isNotEmpty ? error : 'Test ${index + 1}: Wrong Answer');
    }

    testResults.add({
      'id': result['id']?.toString() ?? 'test-${index + 1}',
      'passed': isCorrect,
      'output': _display(result['output']),
      'expected': _display(result['correctAnswer']),
      'error': isCorrect ? null : (error.isNotEmpty ? error : 'Wrong Answer'),
    });
  }

  return {
    'status': passed ? 'passed' : 'failed',
    'stdout': _truncate(logs.join('\n'), 65536),
    'stderr': _truncate(errors.join('\n'), 65536),
    'executionTimeMs': elapsedMs,
    'memoryUsageBytes': null,
    'passedTests': passedTests,
    'totalTests': totalTests,
    'testResults': testResults,
  };
}

Map<String, Object?> _failure({
  required String status,
  required String message,
  required int elapsedMs,
  required int totalTests,
}) {
  return {
    'status': status,
    'stdout': '',
    'stderr': _truncate(message, 65536),
    'executionTimeMs': elapsedMs,
    'memoryUsageBytes': null,
    'passedTests': 0,
    'totalTests': totalTests,
    'testResults': <Object?>[],
  };
}

String _display(Object? value) {
  if (value == null) return '';
  if (value is String) return value;

  try {
    return jsonEncode(value);
  } on Object {
    return value.toString();
  }
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String _backendError(_BackendResponse response) {
  try {
    final decoded = response.jsonObject();
    return decoded['error']?.toString() ??
        'Cojudge returned HTTP ${response.statusCode}';
  } on Object {
    return 'Cojudge returned HTTP ${response.statusCode}: '
        '${_truncate(response.body, 1000)}';
  }
}

String _truncate(String value, int maxLength) {
  if (value.length <= maxLength) return value;
  return '${value.substring(0, maxLength)}…';
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

class _BackendResponse {
  const _BackendResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;

  Map<String, Object?> jsonObject() {
    final decoded = jsonDecode(body);

    if (decoded is! Map) {
      throw const FormatException('Cojudge response must be a JSON object');
    }

    return Map<String, Object?>.from(decoded);
  }
}

class _BackendException implements Exception {
  const _BackendException(this.message);

  final String message;

  @override
  String toString() => message;
}
