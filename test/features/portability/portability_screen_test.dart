import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/app/app_controller.dart';
import 'package:offline_leetcode_trainer/core/storage/app_state.dart';
import 'package:offline_leetcode_trainer/features/portability/portability_screen.dart';
import 'package:offline_leetcode_trainer/features/portability/progress_archive_service.dart';
import 'package:offline_leetcode_trainer/features/problems/problem.dart';

void main() {
  testWidgets('portability actions fit Android portrait without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AppController(
      problem: _problem,
      state: const AppState(),
      progressArchiveService: ProgressArchiveService(
        supportDirectory: Directory.systemTemp,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: PortabilityScreen(controller: controller)),
    );

    for (final label in [
      'EXPORT PROGRESS',
      'EXPORT + MATERIALS',
      'IMPORT',
      'SHARE PROGRESS',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}

final _problem = Problem(
  id: 1,
  slug: 'two-sum',
  title: 'Two Sum',
  difficulty: 'easy',
  topics: const [],
  description: '',
  examples: const [],
  constraints: const [],
  starterCodeByLanguage: const {'python': ''},
  testCases: const [],
  source: 'local',
  sourceUrl: '',
);
