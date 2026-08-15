import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/materials/learning_material.dart';
import 'package:offline_leetcode_trainer/features/materials/learning_materials_panel.dart';

void main() {
  testWidgets('shows attachment metadata and all material actions', (
    tester,
  ) async {
    const material = LearningMaterial(
      id: 'one',
      name: 'walkthrough.md',
      path: '/private/walkthrough.md',
      kind: LearningMaterialKind.markdown,
      extension: 'md',
      sizeBytes: 1536,
    );
    var materialImports = 0;
    var replacements = 0;
    var removals = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearningMaterialsPanel(
            title: 'Two Sum',
            materials: const [material],
            onAddMaterial: () async => materialImports++,
            onReplace: (_) async => replacements++,
            onRemove: (_) async => removals++,
            onExternalOpen: (_) async {},
          ),
        ),
      ),
    );

    expect(find.text('walkthrough.md'), findsOneWidget);
    expect(find.textContaining('MARKDOWN'), findsOneWidget);
    expect(find.textContaining('1.5 KB'), findsOneWidget);
    expect(find.textContaining('permission'), findsOneWidget);

    await tester.tap(find.text('ADD MATERIAL'));
    await tester.tap(find.text('REPLACE'));
    await tester.tap(find.text('REMOVE'));
    expect(materialImports, 1);
    expect(find.text('IMPORT ANIMATION'), findsNothing);
    expect(replacements, 1);
    expect(removals, 1);

    await tester.tap(find.text('OPEN'));
    await tester.pump();
    expect(find.text('MATERIAL/WALKTHROUGH.MD'), findsOneWidget);
  });

  testWidgets('empty state keeps both import actions available', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearningMaterialsPanel(
            title: 'Two Sum',
            materials: const [],
            onAddMaterial: () async {},
          ),
        ),
      ),
    );

    expect(find.text('NO LOCAL MATERIALS'), findsOneWidget);
    expect(find.text('IMPORT ANIMATION'), findsNothing);
    expect(find.text('ADD MATERIAL'), findsOneWidget);
  });
}
