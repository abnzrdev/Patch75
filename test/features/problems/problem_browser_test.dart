import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/problems/problem.dart';
import 'package:offline_leetcode_trainer/features/problems/problem_browser.dart';

void main() {
  testWidgets('filters problems by search and difficulty', (tester) async {
    final problems = [
      _problem('two-sum', 'Two Sum', 'easy'),
      _problem('coin-change', 'Coin Change', 'medium'),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProblemBrowser(problems: problems, onSelected: (_) {}),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'coin');
    await tester.pump();
    expect(find.text('Coin Change'), findsOneWidget);
    expect(find.text('Two Sum'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('EASY'));
    await tester.pump();
    expect(find.text('Two Sum'), findsOneWidget);
    expect(find.text('Coin Change'), findsNothing);
  });
}

Problem _problem(String slug, String title, String difficulty) =>
    Problem.fromJson(
      jsonDecode('''
{"id":1,"slug":"$slug","title":"$title","difficulty":"$difficulty",
"topics":["array"],"description":"","examples":[],"constraints":[],
"starterCodeByLanguage":{"python":"pass"},"testCases":[],
"source":"Patch75","sourceUrl":"","license":"AGPL-3.0-only","originalContent":true}
''')
          as Map<String, Object?>,
    );
