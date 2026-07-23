import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/app_controller.dart';
import '../../core/design/olt_design.dart';
import 'progress_archive_service.dart';

class PortabilityScreen extends StatefulWidget {
  const PortabilityScreen({required this.controller, super.key});
  final AppController controller;

  @override
  State<PortabilityScreen> createState() => _PortabilityScreenState();
}

class _PortabilityScreenState extends State<PortabilityScreen> {
  bool _busy = false;
  String? _message;

  ProgressArchiveService get _service =>
      widget.controller.progressArchiveService!;

  Future<void> _export({required bool materials, required bool share}) async {
    await _run(() async {
      final bytes = Uint8List.fromList(
        await _service.export(
          widget.controller.state,
          includeMaterials: materials,
        ),
      );
      final name =
          'olt-progress-${DateTime.now().toUtc().toIso8601String().split('T').first}.olt.zip';
      if (share) {
        final directory = await Directory.systemTemp.createTemp('olt-share-');
        final file = File('${directory.path}/$name');
        await file.writeAsBytes(bytes, flush: true);
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: 'Patch75 progress'),
        );
        _message = 'Share sheet opened.';
      } else {
        final path = await FilePicker.saveFile(
          dialogTitle: 'Export progress',
          fileName: name,
          type: FileType.custom,
          allowedExtensions: const ['zip'],
          bytes: bytes,
        );
        _message = path == null ? 'Export cancelled.' : 'Progress exported.';
      }
    });
  }

  Future<void> _import() async {
    await _run(() async {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['zip'],
      );
      if (picked == null) {
        _message = 'Import cancelled.';
        return;
      }
      final bytes = picked.path == null
          ? await picked.readAsBytes()
          : await File(picked.path!).readAsBytes();
      final preview = _service.preview(bytes);
      if (!mounted) return;
      final mode = await showDialog<ImportMode>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('IMPORT PROGRESS'),
          content: Text(
            '${preview.problemCount} problems · ${preview.materialCount} materials\n'
            'Exported ${preview.exportedAtUtc.toLocal()}\n\n'
            'Merge preserves local conflicts. Replace restores the archive after creating a private backup.',
          ),
          actions: [
            OltButton(label: 'CANCEL', onPressed: () => Navigator.pop(context)),
            OltButton(
              label: 'REPLACE',
              onPressed: () => Navigator.pop(context, ImportMode.replace),
            ),
            OltButton(
              label: 'MERGE',
              signal: true,
              onPressed: () => Navigator.pop(context, ImportMode.merge),
            ),
          ],
        ),
      );
      if (mode == null) return;
      await widget.controller.importProgress(bytes, mode);
      _message = 'Progress imported. A rollback backup was kept locally.';
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } on Object catch (error) {
      _message = 'Operation failed: $error';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PROGRESS PORTABILITY')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(OltSpace.x4),
        child: OltPanel(
          label: 'PRIVATE / LOCAL / VERSIONED ZIP',
          child: ListView(
            padding: const EdgeInsets.all(OltSpace.x4),
            children: [
              const Text(
                'Move your learning progress between devices.',
                style: TextStyle(color: OltColors.foreground, fontSize: 18),
              ),
              const SizedBox(height: OltSpace.x2),
              const Text(
                'Exports stay on your device unless you explicitly save or share them. Imported files are validated before anything changes.',
                style: TextStyle(color: OltColors.readable, height: 1.5),
              ),
              const SizedBox(height: OltSpace.x6),
              Wrap(
                spacing: OltSpace.x2,
                runSpacing: OltSpace.x2,
                children: [
                  OltButton(
                    label: 'EXPORT PROGRESS',
                    signal: true,
                    onPressed: _busy
                        ? null
                        : () => _export(materials: false, share: false),
                  ),
                  OltButton(
                    label: 'EXPORT + MATERIALS',
                    onPressed: _busy
                        ? null
                        : () => _export(materials: true, share: false),
                  ),
                  OltButton(label: 'IMPORT', onPressed: _busy ? null : _import),
                  OltButton(
                    label: 'SHARE PROGRESS',
                    onPressed: _busy
                        ? null
                        : () => _export(materials: false, share: true),
                  ),
                ],
              ),
              if (_busy) ...[
                const SizedBox(height: OltSpace.x4),
                const LinearProgressIndicator(),
              ],
              if (_message != null) ...[
                const SizedBox(height: OltSpace.x4),
                Text(
                  _message!,
                  style: const TextStyle(color: OltColors.readable),
                ),
              ],
              const SizedBox(height: OltSpace.x6),
              const Text(
                'For same-network transfer, export the ZIP and send it with LocalSend or another tool you trust. The app never starts a network service.',
                style: TextStyle(color: OltColors.muted, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
