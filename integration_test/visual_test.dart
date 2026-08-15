import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offline_leetcode_trainer/app/app_controller.dart';
import 'package:offline_leetcode_trainer/app/offline_trainer_app.dart';
import 'package:offline_leetcode_trainer/core/storage/app_state.dart';
import 'package:offline_leetcode_trainer/features/problems/problem_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture verified Linux workspace states', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    final problems = await AssetProblemRepository(rootBundle).loadAll();
    final controller = AppController(
      problem: problems.singleWhere((problem) => problem.slug == 'two-sum'),
      problems: problems,
      state: const AppState(),
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('capture-boundary'),
        child: OfflineTrainerApp(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    await _save(
      'screenshots/runtime/linux-workspace.png',
      await _capture(tester),
    );
    await tester.tap(find.byKey(const Key('focus-toggle')));
    await tester.pumpAndSettle();
    await _save('screenshots/runtime/linux-focus.png', await _capture(tester));
  });
}

Future<void> _save(String path, List<int> bytes) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
}

Future<List<int>> _capture(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('capture-boundary')),
  );
  final image = await boundary.toImage();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}
