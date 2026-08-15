import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../custom_tests/custom_test_editor.dart';
import '../materials/learning_materials_panel.dart';
import 'complexity_check_panel.dart';
import 'hint_panel.dart';

class LearningToolsPanel extends StatelessWidget {
  const LearningToolsPanel({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: Column(
      children: [
        const TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: 'MATERIALS'),
            Tab(text: 'HINTS'),
            Tab(text: 'CUSTOM TESTS'),
            Tab(text: 'COMPLEXITY'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              LearningMaterialsPanel(
                title: controller.problem.title,
                materials: controller.materials,
                busy: controller.importingMaterial,
                errorMessage: controller.materialError,
                onAddMaterial: controller.addMaterial,
                onReplace: controller.replaceMaterial,
                onRemove: controller.removeMaterial,
                onExternalOpen: controller.openMaterial,
              ),
              HintPanel(
                hints: controller.problem.hints,
                revealedLevels: controller.revealedHintLevels,
                onRevealNext: controller.revealNextHint,
              ),
              CustomTestEditor(controller: controller),
              ComplexityCheckPanel(
                expectedTime: controller.problem.expectedTimeComplexity,
                expectedSpace: controller.problem.expectedSpaceComplexity,
                expectedExplanation: controller.problem.complexityExplanation,
                onCheck: controller.recordComplexityAnswers,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
