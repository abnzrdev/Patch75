import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app_controller.dart';
import 'app/offline_trainer_app.dart';
import 'core/storage/state_store.dart';
import 'features/judge/judge_service.dart';
import 'features/problems/problem_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final problems = await AssetProblemRepository(rootBundle).loadAll();
  final store = StateStore(await getApplicationSupportDirectory());
  final state = await store.load();
  final controller = AppController(
    problem: problems.firstWhere(
      (problem) => problem.slug == state.selectedProblemSlug,
      orElse: () => problems.firstWhere((problem) => problem.slug == 'two-sum'),
    ),
    problems: problems,
    state: state,
    onSave: store.save,
    judgeService: kIsWeb
        ? const UnsupportedJudgeService()
        : switch (defaultTargetPlatform) {
            TargetPlatform.android => const AndroidPythonJudgeService(),
            TargetPlatform.linux ||
            TargetPlatform.macOS ||
            TargetPlatform.windows => DesktopCojudgeJudgeService(),
            _ => const UnsupportedJudgeService(),
          },
  );
  unawaited(controller.refreshJudgeAvailability());
  runApp(OfflineTrainerApp(controller: controller));
}
