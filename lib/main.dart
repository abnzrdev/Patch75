import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import 'app/app_controller.dart';
import 'app/offline_trainer_app.dart';
import 'core/storage/state_store.dart';
import 'features/animations/local_animation_store.dart';
import 'features/judge/judge_service.dart';
import 'features/materials/local_material_store.dart';
import 'features/problems/problem_repository.dart';
import 'features/review/fsrs_scheduler_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final problems = await AssetProblemRepository(rootBundle).loadAll();
  final supportDirectory = await getApplicationSupportDirectory();
  final store = StateStore(supportDirectory);
  final state = await store.load();
  final controller = AppController(
    problem: problems.firstWhere(
      (problem) => problem.slug == state.selectedProblemSlug,
      orElse: () => problems.firstWhere((problem) => problem.slug == 'two-sum'),
    ),
    problems: problems,
    state: state,
    onSave: store.save,
    animationStore: LocalAnimationStore(supportDirectory: supportDirectory),
    materialStore: LocalMaterialStore(supportDirectory: supportDirectory),
    materialOpener: (material) async {
      try {
        final result = await OpenFilex.open(material.path);
        return result.type == ResultType.done
            ? null
            : 'Could not open ${material.name}: ${result.message}';
      } on Object catch (error) {
        return 'Could not open ${material.name}: $error';
      }
    },
    reviewScheduler: FsrsSchedulerService(
      desiredRetention:
          (state.settings['desiredRetention'] as num?)?.toDouble() ?? 0.90,
    ),
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
  await controller.initializeReviews();
  unawaited(controller.refreshJudgeAvailability());
  runApp(OfflineTrainerApp(controller: controller));
}
