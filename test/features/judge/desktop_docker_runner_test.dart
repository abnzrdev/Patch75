import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/judge/desktop_docker_runner.dart';
import 'package:offline_leetcode_trainer/features/judge/judge_models.dart';

void main() {
  test('builds a locked-down Docker argument array without source code', () {
    const request = JudgeRequest(
      problemSlug: 'two-sum',
      language: 'python',
      sourceCode: r'dangerous $(touch /tmp/host)',
      selectedTests: ['sample-1'],
    );

    final arguments = dockerArguments('olt-123');

    expect(arguments, containsAllInOrder(['run', '--rm', '--name', 'olt-123']));
    expect(arguments, containsAll(['--network', 'none']));
    expect(arguments, containsAll(['--cap-drop', 'ALL']));
    expect(arguments, contains('--read-only'));
    expect(arguments, containsAll(['--pids-limit', '64']));
    expect(arguments, containsAll(['--memory', '128m']));
    expect(arguments.join(' '), isNot(contains(request.sourceCode)));
    expect(arguments.join(' '), isNot(contains('-v ')));
  });

  test('encodes only validated structured input for the container', () {
    const request = JudgeRequest(
      problemSlug: 'two-sum',
      language: 'python',
      sourceCode: 'class Solution: pass',
      selectedTests: ['sample-1'],
    );
    final payload = dockerPayload(request, [
      const JudgeTestInput(
        id: 'sample-1',
        values: {
          'nums': [2, 7],
          'target': 9,
        },
      ),
    ]);

    expect(payload, contains('"sourceCode":"class Solution: pass"'));
    expect(payload, contains('"id":"sample-1"'));
  });
}
