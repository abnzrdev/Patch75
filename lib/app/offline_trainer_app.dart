import 'package:flutter/material.dart';

import '../core/design/olt_design.dart';
import '../features/workspace/workspace_screen.dart';
import 'app_controller.dart';

class OfflineTrainerApp extends StatelessWidget {
  const OfflineTrainerApp({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Offline LeetCode Trainer',
    theme: buildOltTheme(),
    home: WorkspaceScreen(controller: controller),
  );
}
