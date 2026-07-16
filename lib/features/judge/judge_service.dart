import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

import 'judge_models.dart';

abstract interface class JudgeService {
  Future<bool> isAvailable();

  Future<JudgeResult> run(JudgeRequest request, List<JudgeTestInput> tests);
}

class DesktopCojudgeJudgeService implements JudgeService {
  DesktopCojudgeJudgeService({http.Client? client})
    : _client = client ?? http.Client();

  static final _endpoint = Uri.parse('http://127.0.0.1:5376');
  final http.Client _client;

  @override
  Future<bool> isAvailable() async {
    try {
      final response = await _client
          .get(_endpoint.resolve('/health'))
          .timeout(const Duration(milliseconds: 750));
      return response.statusCode == 200;
    } on Object {
      return false;
    }
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
              'tests': tests.map((test) => test.toJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 10));
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
