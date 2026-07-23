import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' as io;

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'judge_models.dart';

abstract interface class JudgeService {
  Future<bool> isAvailable();

  Future<JudgeResult> run(JudgeRequest request, List<JudgeTestInput> tests);
}

class DesktopCojudgeJudgeService implements JudgeService {
  DesktopCojudgeJudgeService({
    http.Client? client,
    this._healthTimeout = const Duration(seconds: 1),
    this._retryDelay = const Duration(milliseconds: 200),
  }) : _client = client ?? _createDirectClient();

  static final _endpoint = Uri.parse('http://127.0.0.1:5376');

  final http.Client _client;
  final Duration _healthTimeout;
  final Duration _retryDelay;

  static http.Client _createDirectClient() {
    final client = io.HttpClient();
    client.findProxy = (_) => 'DIRECT';
    return IOClient(client);
  }

  @override
  Future<bool> isAvailable() async {
    Object? lastError;
    StackTrace? lastStackTrace;

    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        final response = await _client
            .get(_endpoint.resolve('/health'))
            .timeout(_healthTimeout);

        if (response.statusCode != 200) {
          throw http.ClientException(
            'Judge health returned HTTP ${response.statusCode}',
            _endpoint.resolve('/health'),
          );
        }

        final payload = jsonDecode(response.body);

        if (payload is! Map<String, dynamic> || payload['status'] != 'ok') {
          throw const FormatException(
            'Judge health response must contain status "ok"',
          );
        }

        return true;
      } on Object catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;

        if (attempt < 3) {
          await Future<void>.delayed(_retryDelay);
        }
      }
    }

    developer.log(
      'Desktop judge health check failed after 3 attempts',
      name: 'offline_leetcode_trainer.judge',
      error: lastError,
      stackTrace: lastStackTrace,
    );

    return false;
  }

  @override
  Future<JudgeResult> run(
    JudgeRequest request,
    List<JudgeTestInput> tests,
  ) async {
    request.validate();
    try {
      final response = await _client
          .post(
            _endpoint.resolve('/judge'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'problemSlug': request.problemSlug,
              'language': request.language,
              'sourceCode': request.sourceCode,
              'selectedTests': request.selectedTests,
              'mode': request.mode.name,
              'submit': request.submit,
              'tests': tests.map((test) => test.toJson()).toList(),
            }),
          )
          .timeout(
            request.submit
                ? const Duration(minutes: 5)
                : const Duration(minutes: 2),
          );
      if (response.statusCode != 200 ||
          response.bodyBytes.length > 256 * 1024) {
        throw const FormatException('Invalid judge response');
      }
      return JudgeResult.fromJson(
        jsonDecode(response.body) as Map<String, Object?>,
      );
    } on Object catch (error) {
      return JudgeResult(
        status: JudgeStatus.unavailable,
        stdout: '',
        stderr: 'Desktop judge unavailable: $error',
        executionTimeMs: 0,
        memoryUsageBytes: null,
        passedTests: 0,
        totalTests: tests.length,
        testResults: const [],
      );
    }
  }
}

class UnsupportedJudgeService implements JudgeService {
  const UnsupportedJudgeService();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<JudgeResult> run(
    JudgeRequest request,
    List<JudgeTestInput> tests,
  ) async => JudgeResult(
    status: JudgeStatus.unavailable,
    stdout: '',
    stderr: 'Offline code execution is unavailable on this platform.',
    executionTimeMs: 0,
    memoryUsageBytes: null,
    passedTests: 0,
    totalTests: tests.length,
    testResults: const [],
  );
}

class AndroidPythonJudgeService implements JudgeService {
  const AndroidPythonJudgeService();

  static const channelName = 'dev.abnzr.offline_leetcode_trainer/python_judge';
  static const _channel = MethodChannel(channelName);

  @override
  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('available') ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<JudgeResult> run(
    JudgeRequest request,
    List<JudgeTestInput> tests,
  ) async {
    request.validate();
    final payload = jsonEncode({
      'problemSlug': request.problemSlug,
      'language': request.language,
      'sourceCode': request.sourceCode,
      'selectedTests': request.selectedTests,
      'mode': request.mode.name,
      'tests': tests.map((test) => test.toJson()).toList(),
    });
    if (utf8.encode(payload).length > 256 * 1024) {
      throw ArgumentError('Judge payload exceeds 262144 bytes');
    }
    try {
      final response = await _channel
          .invokeMethod<String>('run', payload)
          .timeout(const Duration(seconds: 8));
      if (response == null || utf8.encode(response).length > 256 * 1024) {
        throw const FormatException('Invalid Android judge response');
      }
      return JudgeResult.fromJson(jsonDecode(response) as Map<String, Object?>);
    } on PlatformException catch (error) {
      if (error.message?.contains('Time Limit Exceeded') ?? false) {
        return JudgeResult(
          status: JudgeStatus.timeout,
          stdout: '',
          stderr: 'Time Limit Exceeded',
          executionTimeMs: 7000,
          memoryUsageBytes: null,
          passedTests: 0,
          totalTests: tests.length,
          testResults: const [],
        );
      }
      return _unavailable(error, tests.length);
    } on TimeoutException catch (error) {
      return JudgeResult(
        status: JudgeStatus.timeout,
        stdout: '',
        stderr: error.toString(),
        executionTimeMs: 8000,
        memoryUsageBytes: null,
        passedTests: 0,
        totalTests: tests.length,
        testResults: const [],
      );
    } on Object catch (error) {
      return _unavailable(error, tests.length);
    }
  }

  JudgeResult _unavailable(Object error, int totalTests) => JudgeResult(
    status: JudgeStatus.unavailable,
    stdout: '',
    stderr: 'Android Python judge unavailable: $error',
    executionTimeMs: 0,
    memoryUsageBytes: null,
    passedTests: 0,
    totalTests: totalTests,
    testResults: const [],
  );
}
