import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../core/design/olt_design.dart';
import 'learning_material.dart';

class MaterialViewer extends StatelessWidget {
  const MaterialViewer({
    required this.material,
    this.onExternalOpen,
    this.fileExists,
    this.textLoader,
    super.key,
  });

  final LearningMaterial material;
  final Future<void> Function()? onExternalOpen;
  final bool Function(String path)? fileExists;
  final Future<String> Function(String path)? textLoader;

  @override
  Widget build(BuildContext context) {
    final file = File(material.path);
    if (!(fileExists?.call(material.path) ?? file.existsSync())) {
      return const _Unavailable();
    }

    return switch (material.kind) {
      LearningMaterialKind.image => InteractiveViewer(
        minScale: .5,
        maxScale: 4,
        child: Image.file(
          file,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          semanticLabel: material.name,
          errorBuilder: (_, _, _) => const _Unavailable(),
        ),
      ),
      LearningMaterialKind.markdown => _LocalText(
        path: file.path,
        loader: textLoader,
        markdown: true,
      ),
      LearningMaterialKind.text => _LocalText(
        path: file.path,
        loader: textLoader,
      ),
      LearningMaterialKind.pdf || LearningMaterialKind.video => Center(
        child: Padding(
          padding: const EdgeInsets.all(OltSpace.x4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                material.kind == LearningMaterialKind.pdf
                    ? Icons.picture_as_pdf_outlined
                    : Icons.movie_outlined,
                size: 48,
                color: OltColors.muted,
              ),
              const SizedBox(height: OltSpace.x3),
              Text(material.name, textAlign: TextAlign.center),
              const SizedBox(height: OltSpace.x3),
              OltButton(
                label: 'OPEN WITH SYSTEM VIEWER',
                onPressed: onExternalOpen,
              ),
            ],
          ),
        ),
      ),
    };
  }
}

class _LocalText extends StatefulWidget {
  const _LocalText({required this.path, this.loader, this.markdown = false});

  final String path;
  final Future<String> Function(String path)? loader;
  final bool markdown;

  @override
  State<_LocalText> createState() => _LocalTextState();
}

class _LocalTextState extends State<_LocalText> {
  late Future<String> content;

  @override
  void initState() {
    super.initState();
    content = _load();
  }

  @override
  void didUpdateWidget(covariant _LocalText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      content = _load();
    }
  }

  Future<String> _load() =>
      widget.loader?.call(widget.path) ?? File(widget.path).readAsString();

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: content,
    builder: (context, snapshot) {
      if (snapshot.hasError) return const _Unavailable();
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!widget.markdown) {
        return SelectionArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(OltSpace.x4),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(snapshot.data!, style: const TextStyle(height: 1.55)),
            ),
          ),
        );
      }
      return SelectionArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(OltSpace.x4),
          child: MarkdownBody(
            data: snapshot.data!,
            imageBuilder: (_, _, alt) =>
                Text('[IMAGE DISABLED: ${alt ?? 'local'}]'),
            onTapLink: (_, _, _) {},
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .copyWith(
                  p: const TextStyle(color: OltColors.foreground, height: 1.55),
                  code: const TextStyle(
                    color: OltColors.signal,
                    backgroundColor: OltColors.raised,
                    fontFamily: 'monospace',
                  ),
                ),
          ),
        ),
      );
    },
  );
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(OltSpace.x4),
      child: Text('FILE/UNAVAILABLE', style: microStyle),
    ),
  );
}
