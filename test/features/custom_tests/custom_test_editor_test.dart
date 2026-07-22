import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/app/app_controller.dart';
import 'package:offline_leetcode_trainer/core/storage/app_state.dart';
import 'package:offline_leetcode_trainer/features/custom_tests/custom_test_editor.dart';
import 'package:offline_leetcode_trainer/features/problems/problem.dart';

void main() {
  testWidgets('custom-test editor offers structured and advanced JSON modes', (
    tester,
  ) async {
    final controller = AppController(
      problem: Problem.fromJson(
        jsonDecode(_problemJson) as Map<String, Object?>,
      ),
      state: const AppState(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CustomTestEditor(controller: controller)),
      ),
    );

    await tester.tap(find.text('CREATE CUSTOM TEST'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('custom-field-nums')), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-field-target')), findsOneWidget);
    await tester.tap(find.text('Advanced JSON input'));
    await tester.pump();
    expect(find.byKey(const Key('custom-test-json')), findsOneWidget);
    controller.dispose();
  });
}

const _problemJson = r'''
{"id":1,"slug":"two-sum","title":"Two Sum","difficulty":"easy","topics":["array"],"description":"Find indices.","examples":[],"constraints":[],"starterCodeByLanguage":{"python":"class Solution: pass"},"testCases":[{"id":"sample-1","input":{"nums":[2,7],"target":9},"expected":[0,1],"sample":true}],"source":"cojudge","sourceUrl":"https://github.com/cojudge/cojudge"}
''';
