import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/materials/learning_material.dart';
import 'package:offline_leetcode_trainer/features/materials/material_viewer.dart';

void main() {
  testWidgets('renders Markdown and text locally as selectable content', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const LearningMaterial(
          id: 'md',
          name: 'guide.md',
          path: '/private/guide.md',
          kind: LearningMaterialKind.markdown,
          extension: 'md',
          sizeBytes: 20,
        ),
        content: '# Guide\n\nUse `dict`.',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Guide'), findsOneWidget);
    expect(
      tester
          .widgetList<RichText>(find.byType(RichText))
          .any((widget) => widget.text.toPlainText().contains('dict')),
      isTrue,
    );

    await tester.pumpWidget(
      _app(
        const LearningMaterial(
          id: 'txt',
          name: 'notes.txt',
          path: '/private/notes.txt',
          kind: LearningMaterialKind.text,
          extension: 'txt',
          sizeBytes: 11,
        ),
        content: 'local notes',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('local notes'), findsOneWidget);
    expect(find.byType(SelectionArea), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('uses an explicit external action for PDF and video', (
    tester,
  ) async {
    var opens = 0;
    await tester.pumpWidget(
      _app(
        const LearningMaterial(
          id: 'pdf',
          name: 'guide.pdf',
          path: '/private/guide.pdf',
          kind: LearningMaterialKind.pdf,
          extension: 'pdf',
          sizeBytes: 1,
        ),
        onExternalOpen: () {
          opens++;
          return Future<void>.value();
        },
      ),
    );

    expect(find.text('OPEN WITH SYSTEM VIEWER'), findsOneWidget);
    await tester.tap(find.text('OPEN WITH SYSTEM VIEWER'));
    expect(opens, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows a recoverable missing-file state', (tester) async {
    await tester.pumpWidget(
      _app(
        const LearningMaterial(
          id: 'missing',
          name: 'missing.txt',
          path: '/does/not/exist.txt',
          kind: LearningMaterialKind.text,
          extension: 'txt',
          sizeBytes: 1,
        ),
      ),
    );
    expect(find.text('FILE/UNAVAILABLE'), findsOneWidget);
  });
}

Widget _app(
  LearningMaterial material, {
  Future<void> Function()? onExternalOpen,
  String? content,
}) => MaterialApp(
  home: Scaffold(
    body: MaterialViewer(
      material: material,
      onExternalOpen: onExternalOpen,
      fileExists: (_) => material.id != 'missing',
      textLoader: content == null ? null : (_) async => content,
    ),
  ),
);
