import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/learning/complexity_check_panel.dart';
import 'package:offline_leetcode_trainer/features/learning/complexity_checker.dart';
import 'package:offline_leetcode_trainer/features/learning/hint_panel.dart';

void main() {
  testWidgets('hint panel reveals only the next level', (tester) async {
    var reveals = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HintPanel(
            hints: const ['nudge', 'idea', 'pseudocode'],
            revealedLevels: const [1],
            onRevealNext: () => reveals++,
          ),
        ),
      ),
    );

    expect(find.textContaining('nudge'), findsOneWidget);
    expect(find.textContaining('idea'), findsNothing);
    await tester.fling(find.byType(ListView), const Offset(0, -400), 1000);
    await tester.pumpAndSettle();
    expect(find.text('REVEAL ALGORITHM IDEA'), findsOneWidget);
    await tester.tap(find.text('REVEAL ALGORITHM IDEA'));
    expect(reveals, 1);
  });

  testWidgets('complexity panel reports expected comparison', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ComplexityCheckPanel(
            expectedTime: 'O(n)',
            expectedSpace: 'O(1)',
            expectedExplanation: 'one pass',
            onCheck: (time, space) =>
                compareComplexity(time, 'O(n)', space, 'O(1)'),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('time-complexity-field')),
      'o(N)',
    );
    await tester.enterText(
      find.byKey(const Key('space-complexity-field')),
      'O(1)',
    );
    await tester.tap(find.text('CHECK COMPLEXITY'));
    await tester.pump();

    expect(find.textContaining('CORRECT'), findsOneWidget);
    expect(find.textContaining('EXPECTED TIME O(n)'), findsOneWidget);
  });
}
