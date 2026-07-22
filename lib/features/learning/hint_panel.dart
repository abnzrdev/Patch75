import 'package:flutter/material.dart';

import '../../core/design/olt_design.dart';

class HintPanel extends StatelessWidget {
  const HintPanel({
    required this.hints,
    required this.revealedLevels,
    required this.onRevealNext,
    super.key,
  });

  final List<String> hints;
  final List<int> revealedLevels;
  final VoidCallback onRevealNext;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(OltSpace.x3),
    children: [
      const Text(
        'Hints are context for your rating decision. They never change the rating automatically.',
      ),
      const SizedBox(height: OltSpace.x3),
      for (final level in revealedLevels)
        Container(
          key: ValueKey('hint-level-$level'),
          margin: const EdgeInsets.only(bottom: OltSpace.x2),
          padding: const EdgeInsets.all(OltSpace.x3),
          decoration: const BoxDecoration(
            color: OltColors.raised,
            border: Border.fromBorderSide(BorderSide(color: OltColors.border)),
          ),
          child: Text(
            '${_label(level)}\n${hints[level - 1]}',
            style: const TextStyle(height: 1.45),
          ),
        ),
      OltButton(
        label: revealedLevels.isEmpty
            ? 'REVEAL SMALL NUDGE'
            : revealedLevels.length == 1
            ? 'REVEAL ALGORITHM IDEA'
            : 'REVEAL PSEUDOCODE',
        signal: true,
        onPressed: revealedLevels.length < hints.length ? onRevealNext : null,
      ),
    ],
  );
}

String _label(int level) => switch (level) {
  1 => 'LEVEL 1 · SMALL NUDGE',
  2 => 'LEVEL 2 · ALGORITHM OR DATA-STRUCTURE IDEA',
  _ => 'LEVEL 3 · PSEUDOCODE',
};
