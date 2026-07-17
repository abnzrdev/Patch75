import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/animations/animation_viewer.dart';

void main() {
  testWidgets('shows missing state, imports and opens expanded view', (
    tester,
  ) async {
    var imports = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimationViewer(
            title: 'Two Sum',
            assetPath: null,
            onImport: () async {
              imports++;
            },
          ),
        ),
      ),
    );

    expect(find.text('ANIM/LOCAL-ASSET-MISSING'), findsOneWidget);

    await tester.tap(find.text('IMPORT'));
    await tester.pump();

    expect(imports, 1);

    await tester.tap(find.text('EXPAND'));
    await tester.pumpAndSettle();

    expect(find.text('ANIMATION/TWO-SUM'), findsOneWidget);
  });

  testWidgets('shows corrupt fallback when a local file is missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimationViewer(
            title: 'Two Sum',
            assetPath: '/does/not/exist.gif',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ANIM/ASSET-CORRUPT'), findsOneWidget);
  });

  testWidgets('calls remove for an imported animation', (tester) async {
    var removals = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimationViewer(
            title: 'Two Sum',
            assetPath: '/does/not/exist.gif',
            onRemove: () async {
              removals++;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('REMOVE'));
    await tester.pump();

    expect(removals, 1);
  });
}
