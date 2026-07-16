import 'package:flutter/material.dart';

import '../../core/design/olt_design.dart';

class AnimationViewer extends StatefulWidget {
  const AnimationViewer({
    required this.title,
    required this.assetPath,
    super.key,
  });

  final String title;
  final String? assetPath;

  @override
  State<AnimationViewer> createState() => _AnimationViewerState();
}

class _AnimationViewerState extends State<AnimationViewer> {
  bool visible = true;
  bool corrupt = false;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(OltSpace.x2),
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              OltButton(
                label: visible ? 'HIDE' : 'SHOW',
                onPressed: () => setState(() => visible = !visible),
              ),
              const SizedBox(width: OltSpace.x2),
              OltButton(label: 'EXPAND', onPressed: _expand),
              if (constraints.maxWidth >= 400) ...[
                const Spacer(),
                Text(
                  widget.assetPath == null
                      ? 'ANIM/UNAVAILABLE'
                      : 'ANIM/AVAILABLE',
                  style: microStyle,
                ),
              ],
            ],
          ),
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
    if (widget.assetPath == null) return const _MissingAnimation();
    if (corrupt) {
      return const Center(child: Text('ANIM/ASSET-CORRUPT', style: microStyle));
    }
    final image = Image.asset(
      widget.assetPath!,
      fit: BoxFit.contain,
      semanticLabel: '${widget.title} algorithm animation',
      errorBuilder: (context, error, stackTrace) {
        if (!corrupt) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => corrupt = true);
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
                  'ANIMATION/${widget.title.toUpperCase().replaceAll(' ', '-')}',
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, size: 48, color: OltColors.muted),
          SizedBox(height: OltSpace.x2),
          Text('ANIM/LOCAL-ASSET-MISSING', style: microStyle),
          SizedBox(height: OltSpace.x2),
          Text(
            'LeetCodeAnimation media is not bundled because the source has no redistribution license.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
