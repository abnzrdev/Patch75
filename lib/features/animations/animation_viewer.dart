import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/design/olt_design.dart';

class AnimationViewer extends StatefulWidget {
  const AnimationViewer({
    required this.title,
    required this.assetPath,
    this.onImport,
    this.onRemove,
    this.importing = false,
    this.errorMessage,
    super.key,
  });

  final String title;
  final String? assetPath;
  final Future<void> Function()? onImport;
  final Future<void> Function()? onRemove;
  final bool importing;
  final String? errorMessage;

  @override
  State<AnimationViewer> createState() => _AnimationViewerState();
}

class _AnimationViewerState extends State<AnimationViewer> {
  bool visible = true;
  bool corrupt = false;

  @override
  void didUpdateWidget(covariant AnimationViewer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.assetPath != widget.assetPath) {
      corrupt = false;
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(OltSpace.x2),
        child: LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: OltSpace.x2,
            runSpacing: OltSpace.x2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OltButton(
                label: visible ? 'HIDE' : 'SHOW',
                onPressed: () {
                  setState(() => visible = !visible);
                },
              ),
              OltButton(label: 'EXPAND', onPressed: _expand),
              OltButton(
                label: widget.importing
                    ? 'IMPORTING...'
                    : widget.assetPath == null
                    ? 'IMPORT'
                    : 'REPLACE',
                onPressed: widget.importing
                    ? () {}
                    : () {
                        widget.onImport?.call();
                      },
              ),
              if (widget.assetPath != null)
                OltButton(
                  label: 'REMOVE',
                  onPressed: widget.importing
                      ? () {}
                      : () {
                          widget.onRemove?.call();
                        },
                ),
              Text(
                widget.assetPath == null
                    ? 'ANIM/UNAVAILABLE'
                    : 'ANIM/AVAILABLE',
                style: microStyle,
              ),
            ],
          ),
        ),
      ),
      if (widget.errorMessage != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: OltSpace.x2),
          child: Text(
            widget.errorMessage!,
            style: const TextStyle(color: OltColors.danger),
          ),
        ),
      Expanded(
        child: visible
            ? _content(expanded: false)
            : const Center(child: Text('ANIM/HIDDEN', style: microStyle)),
      ),
    ],
  );

  Widget _content({required bool expanded}) {
    if (widget.assetPath == null) {
      return const _MissingAnimation();
    }

    final file = File(widget.assetPath!);

    if (corrupt || !file.existsSync()) {
      return const Center(child: Text('ANIM/ASSET-CORRUPT', style: microStyle));
    }

    final image = Image.file(
      file,
      key: ValueKey(widget.assetPath),
      fit: BoxFit.contain,
      gaplessPlayback: true,
      semanticLabel: '${widget.title} algorithm animation',
      errorBuilder: (context, error, stackTrace) {
        if (!corrupt) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => corrupt = true);
            }
          });
        }

        return const Center(
          child: Text('ANIM/ASSET-CORRUPT', style: microStyle),
        );
      },
    );

    return expanded
        ? InteractiveViewer(minScale: .5, maxScale: 4, child: image)
        : image;
  }

  Future<void> _expand() => showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      backgroundColor: OltColors.background,
      child: Column(
        children: [
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: OltSpace.x2),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: OltColors.border)),
            ),
            child: Row(
              children: [
                Text(
                  'ANIMATION/'
                  '${widget.title.toUpperCase().replaceAll(' ', '-')}',
                  style: microStyle,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Close expanded animation',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(child: _content(expanded: true)),
        ],
      ),
    ),
  );
}

class _MissingAnimation extends StatelessWidget {
  const _MissingAnimation();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(OltSpace.x4),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, size: 48, color: OltColors.muted),
            SizedBox(height: OltSpace.x2),
            Text('ANIM/LOCAL-ASSET-MISSING', style: microStyle),
            SizedBox(height: OltSpace.x2),
            Text(
              'Import a GIF, WebP, PNG, or JPEG file that you '
              'created or have permission to use.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
