import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:offline_leetcode_trainer/features/judge/judge_models.dart';
import 'package:offline_leetcode_trainer/features/judge/judge_service.dart';

void main() {
  group('desktop judge availability', () {
    test('accepts HTTP 200 with status ok', () async {
      var calls = 0;

      final service = DesktopCojudgeJudgeService(
        client: MockClient((request) async {
          calls++;
          expect(request.url.host, '127.0.0.1');
          expect(request.url.port, 5376);
          expect(request.url.path, '/health');

          return http.Response(jsonEncode({'status': 'ok'}), 200);
        }),
        retryDelay: Duration.zero,
      );

      expect(await service.isAvailable(), isTrue);
      expect(calls, 1);
    });

    test('rejects HTTP 500 after three attempts', () async {
      var calls = 0;

      final service = DesktopCojudgeJudgeService(
        client: MockClient((request) async {
          calls++;
          return http.Response(jsonEncode({'status': 'error'}), 500);
        }),
        retryDelay: Duration.zero,
      );

      expect(await service.isAvailable(), isFalse);
      expect(calls, 3);
    });

    test('rejects malformed JSON after three attempts', () async {
      var calls = 0;

      final service = DesktopCojudgeJudgeService(
        client: MockClient((request) async {
          calls++;
          return http.Response('not-json', 200);
        }),
        retryDelay: Duration.zero,
      );

      expect(await service.isAvailable(), isFalse);
      expect(calls, 3);
    });

    test('rejects timeout after three attempts', () async {
      var calls = 0;

      final service = DesktopCojudgeJudgeService(
        client: MockClient((request) async {
          calls++;

          await Future<void>.delayed(const Duration(milliseconds: 30));

          return http.Response(jsonEncode({'status': 'ok'}), 200);
        }),
        healthTimeout: const Duration(milliseconds: 2),
        retryDelay: Duration.zero,
      );

      expect(await service.isAvailable(), isFalse);
      expect(calls, 3);
    });

    test('succeeds when a retry reaches the judge', () async {
      var calls = 0;

      final service = DesktopCojudgeJudgeService(
        client: MockClient((request) async {
          calls++;

          if (calls < 3) {
            throw http.ClientException(
              'Temporary connection failure',
              request.url,
            );
          }

          return http.Response(jsonEncode({'status': 'ok'}), 200);
        }),
        retryDelay: Duration.zero,
      );

      expect(await service.isAvailable(), isTrue);
      expect(calls, 3);
    });
  });

  test('desktop service posts structured requests only to loopback', () async {
    http.Request? sent;

    final service = DesktopCojudgeJudgeService(
      client: MockClient((request) async {
        sent = request;

        return http.Response(
          jsonEncode({
            'status': 'passed',
            'stdout': '',
            'stderr': '',
            'executionTimeMs': 7,
            'memoryUsageBytes': null,
            'passedTests': 1,
            'totalTests': 1,
            'testResults': [
              {
                'id': 'sample-1',
                'passed': true,
                'output': '[0,1]',
                'expected': '[0,1]',
                'error': null,
              },
            ],
          }),
          200,
        );
      }),
    );

    final result = await service.run(
      const JudgeRequest(
        problemSlug: 'two-sum',
        language: 'python',
        sourceCode: 'class Solution: pass',
        selectedTests: ['sample-1'],
      ),
      const [
        JudgeTestInput(
          id: 'sample-1',
          values: {
            'nums': [2, 7],
            'target': 9,
          },
        ),
      ],
    );

    expect(sent!.url.host, '127.0.0.1');
    expect(sent!.url.port, 5376);
    expect(jsonDecode(sent!.body), containsPair('problemSlug', 'two-sum'));
    expect(result.status, JudgeStatus.passed);
  });
}
