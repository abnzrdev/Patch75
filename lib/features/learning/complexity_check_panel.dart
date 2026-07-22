import 'package:flutter/material.dart';

import '../../core/design/olt_design.dart';
import 'complexity_checker.dart';

class ComplexityCheckPanel extends StatefulWidget {
  const ComplexityCheckPanel({
    required this.expectedTime,
    required this.expectedSpace,
    required this.expectedExplanation,
    required this.onCheck,
    super.key,
  });

  final String expectedTime;
  final String expectedSpace;
  final String expectedExplanation;
  final ComplexityComparison Function(String time, String space) onCheck;

  @override
  State<ComplexityCheckPanel> createState() => _ComplexityCheckPanelState();
}

class _ComplexityCheckPanelState extends State<ComplexityCheckPanel> {
  final time = TextEditingController();
  final space = TextEditingController();
  ComplexityComparison? result;

  @override
  void dispose() {
    time.dispose();
    space.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(OltSpace.x3),
    children: [
      const Text(
        'Enter your analysis. The trainer compares metadata; it does not infer complexity from arbitrary code.',
      ),
      const SizedBox(height: OltSpace.x3),
      TextField(
        key: const Key('time-complexity-field'),
        controller: time,
        decoration: const InputDecoration(labelText: 'Time complexity'),
      ),
      const SizedBox(height: OltSpace.x2),
      TextField(
        key: const Key('space-complexity-field'),
        controller: space,
        decoration: const InputDecoration(labelText: 'Space complexity'),
      ),
      const SizedBox(height: OltSpace.x3),
      OltButton(
        label: 'CHECK COMPLEXITY',
        signal: true,
        onPressed: () =>
            setState(() => result = widget.onCheck(time.text, space.text)),
      ),
      if (result != null) ...[
        const SizedBox(height: OltSpace.x3),
        Text(
          '${_label(result!.status)}\n'
          'EXPECTED TIME ${widget.expectedTime} · SPACE ${widget.expectedSpace}\n'
          '${result!.explanation}\n${widget.expectedExplanation}',
          style: TextStyle(
            color: result!.status == ComplexityStatus.correct
                ? OltColors.signal
                : OltColors.foreground,
            height: 1.45,
          ),
        ),
      ],
    ],
  );
}

String _label(ComplexityStatus value) => switch (value) {
  ComplexityStatus.correct => 'CORRECT',
  ComplexityStatus.partiallyCorrect => 'PARTIALLY CORRECT',
  ComplexityStatus.different => 'DIFFERENT FROM EXPECTED',
};
