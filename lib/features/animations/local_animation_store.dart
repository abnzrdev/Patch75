import 'dart:io';

import 'package:file_picker/file_picker.dart';

typedef AnimationFilePicker = Future<PlatformFile?> Function();

class LocalAnimationStore {
  LocalAnimationStore({
    required this.supportDirectory,
    AnimationFilePicker? picker,
  }) : _picker = picker ?? _pickFile;

  static const allowedExtensions = <String>{
    'gif',
    'webp',
    'png',
    'jpg',
    'jpeg',
  };

  static const maxFileBytes = 64 * 1024 * 1024;

  final Directory supportDirectory;
  final AnimationFilePicker _picker;

  Future<String?> importForProblem(String problemSlug) async {
    _validateSlug(problemSlug);

    final picked = await _picker();
    if (picked == null) return null;

    final extension = _extensionFrom(picked.name);

    if (!allowedExtensions.contains(extension)) {
      throw FormatException('Unsupported animation format: .$extension');
    }

    if (picked.size <= 0 || picked.size > maxFileBytes) {
      throw const FormatException('Animation must be between 1 byte and 64 MB');
    }

    final directory = _problemDirectory(problemSlug);
    await directory.create(recursive: true);

    final version = DateTime.now().microsecondsSinceEpoch;
    final target = File('${directory.path}/animation-$version.$extension');
    final temporary = File('${directory.path}/.import-$version.$extension');

    try {
      final sourcePath = picked.path;

      if (sourcePath != null) {
        final source = File(sourcePath);

        if (!await source.exists()) {
          throw StateError('Selected animation file no longer exists');
        }

        final actualSize = await source.length();

        if (actualSize <= 0 || actualSize > maxFileBytes) {
          throw const FormatException(
            'Animation must be between 1 byte and 64 MB',
          );
        }

        await source.copy(temporary.path);
      } else {
        final bytes = await picked.readAsBytes();
        if (bytes.isEmpty || bytes.length > maxFileBytes) {
          throw const FormatException(
            'Animation must be between 1 byte and 64 MB',
          );
        }
        await temporary.writeAsBytes(bytes, flush: true);
      }

      await temporary.rename(target.path);
      await _deleteOtherAnimations(directory, keepPath: target.path);

      return target.path;
    } finally {
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  }

  Future<void> removeForProblem(String problemSlug) async {
    _validateSlug(problemSlug);

    final directory = _problemDirectory(problemSlug);
    if (!await directory.exists()) return;

    await _deleteOtherAnimations(directory);

    if (await directory.list().isEmpty) {
      await directory.delete();
    }
  }

  Directory _problemDirectory(String slug) =>
      Directory('${supportDirectory.path}/animations/$slug');

  static Future<PlatformFile?> _pickFile() async {
    final extensions = allowedExtensions.toList()..sort();

    return FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
  }

  static String _extensionFrom(String filename) {
    final separator = filename.lastIndexOf('.');

    if (separator <= 0 || separator == filename.length - 1) {
      throw const FormatException('Animation file has no extension');
    }

    return filename.substring(separator + 1).toLowerCase();
  }

  static void _validateSlug(String slug) {
    if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(slug)) {
      throw ArgumentError.value(slug, 'problemSlug');
    }
  }

  static Future<void> _deleteOtherAnimations(
    Directory directory, {
    String? keepPath,
  }) async {
    await for (final entity in directory.list()) {
      if (entity is! File || entity.path == keepPath) continue;

      final filename = entity.uri.pathSegments.last;

      if (_isManagedAnimation(filename)) {
        await entity.delete();
      }
    }
  }

  static bool _isManagedAnimation(String filename) =>
      filename.startsWith('animation-') || filename.startsWith('animation.');
}
