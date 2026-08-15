import 'package:flutter/material.dart';

import '../../core/design/olt_design.dart';
import 'learning_material.dart';
import 'material_viewer.dart';

class LearningMaterialsPanel extends StatelessWidget {
  const LearningMaterialsPanel({
    required this.title,
    required this.materials,
    required this.onAddMaterial,
    this.onReplace,
    this.onRemove,
    this.onExternalOpen,
    this.busy = false,
    this.errorMessage,
    super.key,
  });

  final String title;
  final List<LearningMaterial> materials;
  final Future<void> Function() onAddMaterial;
  final Future<void> Function(LearningMaterial material)? onReplace;
  final Future<void> Function(LearningMaterial material)? onRemove;
  final Future<void> Function(LearningMaterial material)? onExternalOpen;
  final bool busy;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('materials-scroll'),
    padding: const EdgeInsets.all(OltSpace.x2),
    children: [
      Wrap(
        spacing: OltSpace.x2,
        runSpacing: OltSpace.x2,
        children: [
          OltButton(
            label: busy ? 'IMPORTING...' : 'ADD MATERIAL',
            signal: true,
            onPressed: busy ? null : onAddMaterial,
          ),
        ],
      ),
      const SizedBox(height: OltSpace.x2),
      const Text(
        'Import only files you created or have permission to use.',
        style: microStyle,
      ),
      if (errorMessage != null)
        Padding(
          padding: const EdgeInsets.only(top: OltSpace.x2),
          child: Text(
            errorMessage!,
            style: const TextStyle(color: OltColors.danger, fontSize: 12),
          ),
        ),
      const SizedBox(height: OltSpace.x2),
      if (materials.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: OltSpace.x6),
          child: Center(child: Text('NO LOCAL MATERIALS', style: microStyle)),
        )
      else
        for (final (index, material) in materials.indexed) ...[
          if (index > 0) const SizedBox(height: OltSpace.x2),
          _MaterialRow(
            material: material,
            onOpen: () => _open(context, material),
            onReplace: onReplace == null || busy
                ? null
                : () => onReplace!(material),
            onRemove: onRemove == null || busy
                ? null
                : () => onRemove!(material),
          ),
        ],
    ],
  );

  Future<void> _open(BuildContext context, LearningMaterial material) async {
    if (material.kind == LearningMaterialKind.pdf ||
        material.kind == LearningMaterialKind.video) {
      await onExternalOpen?.call(material);
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: OltColors.background,
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  const SizedBox(width: OltSpace.x2),
                  Expanded(
                    child: Text(
                      'MATERIAL/${material.name.toUpperCase()}',
                      style: microStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close material',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: OltColors.border),
            Expanded(child: MaterialViewer(material: material)),
          ],
        ),
      ),
    );
  }
}

class _MaterialRow extends StatelessWidget {
  const _MaterialRow({
    required this.material,
    required this.onOpen,
    this.onReplace,
    this.onRemove,
  });

  final LearningMaterial material;
  final VoidCallback onOpen;
  final VoidCallback? onReplace;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: OltColors.raised,
      border: Border.fromBorderSide(BorderSide(color: OltColors.border)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(OltSpace.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(material.name, overflow: TextOverflow.ellipsis),
          const SizedBox(height: OltSpace.x1),
          Text(
            '${material.friendlyType} · ${formatMaterialSize(material.sizeBytes)}',
            style: microStyle,
          ),
          const SizedBox(height: OltSpace.x2),
          Wrap(
            spacing: OltSpace.x2,
            runSpacing: OltSpace.x2,
            children: [
              OltButton(label: 'OPEN', onPressed: onOpen),
              OltButton(label: 'REPLACE', onPressed: onReplace),
              OltButton(label: 'REMOVE', onPressed: onRemove),
            ],
          ),
        ],
      ),
    ),
  );
}

String formatMaterialSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
