import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/animations/animation_viewer.dart';

void main() {
  testWidgets('shows missing state and opens an expanded view', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimationViewer(title: 'Two Sum', assetPath: null),
        ),
      ),
    );

    expect(find.text('ANIM/LOCAL-ASSET-MISSING'), findsOneWidget);
    await tester.tap(find.text('EXPAND'));
    await tester.pumpAndSettle();
    expect(find.text('ANIMATION/TWO-SUM'), findsOneWidget);
  });

  testWidgets('shows corrupt fallback when an asset cannot decode', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimationViewer(
            title: 'Two Sum',
            assetPath: 'assets/does-not-exist.gif',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ANIM/ASSET-CORRUPT'), findsOneWidget);
  });
}
