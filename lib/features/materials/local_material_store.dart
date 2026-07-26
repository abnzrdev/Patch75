import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'learning_material.dart';

typedef MaterialFilePicker =
    Future<PlatformFile?> Function(Set<String> allowedExtensions);

class LocalMaterialStore {
  LocalMaterialStore({
    required this.supportDirectory,
    MaterialFilePicker? picker,
    this.documentLimitBytes = LocalMaterialStore.maxDocumentBytes,
    this.videoLimitBytes = LocalMaterialStore.maxVideoBytes,
  }) : _picker = picker ?? _pickFile,
       assert(documentLimitBytes > 0),
       assert(videoLimitBytes > 0);

  static const imageExtensions = {'gif', 'webp', 'png', 'jpg', 'jpeg'};
  static const markdownExtensions = {'md', 'markdown'};
  static const textExtensions = {'txt'};
  static const pdfExtensions = {'pdf'};
  static const videoExtensions = {'mp4', 'webm'};
  static const allowedExtensions = {
    ...imageExtensions,
    ...markdownExtensions,
    ...textExtensions,
    ...pdfExtensions,
    ...videoExtensions,
  };
  static const maxDocumentBytes = 64 * 1024 * 1024;
  static const maxVideoBytes = 256 * 1024 * 1024;

  final Directory supportDirectory;
  final MaterialFilePicker _picker;
  final int documentLimitBytes;
  final int videoLimitBytes;

  Future<LearningMaterial?> importForProblem(
    String slug, {
    Set<LearningMaterialKind>? kinds,
    LearningMaterial? replacing,
  }) async {
    _validateSlug(slug);
    final extensions = kinds == null
        ? allowedExtensions
        : allowedExtensions
              .where((value) => kinds.contains(_kind(value)))
              .toSet();
    final picked = await _picker(extensions);
    if (picked == null) return null;

    final name = _basename(picked.name);
    final extension = _extension(name);
    if (!extensions.contains(extension)) {
      throw FormatException('Unsupported material format: .$extension');
    }
    final limit = _kind(extension) == LearningMaterialKind.video
        ? videoLimitBytes
        : documentLimitBytes;
    _validateSize(picked.size, limit);

    final directory = _problemDirectory(slug);
    await directory.create(recursive: true);
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final target = File.fromUri(
      directory.uri.resolve('material-$id.$extension'),
    );
    final temporary = File.fromUri(
      directory.uri.resolve('.import-$id.$extension'),
    );

    try {
      if (picked.path case final path?) {
        final source = File(path);
        if (!await source.exists()) {
          throw StateError('Selected material file no longer exists');
        }
        _validateSize(await source.length(), limit);
        await source.copy(temporary.path);
      } else {
        final bytes = await picked.readAsBytes();
        _validateSize(bytes.length, limit);
        await temporary.writeAsBytes(bytes, flush: true);
      }

      await temporary.rename(target.path);
      final material = LearningMaterial(
        id: id,
        name: name,
        path: target.path,
        kind: _kind(extension),
        extension: extension,
        sizeBytes: await target.length(),
      );
      return material;
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  Future<void> delete(LearningMaterial material, String slug) async {
    _validateSlug(slug);
    final directory = _problemDirectory(slug).absolute;
    final file = File(material.path).absolute;
    if (!file.uri.toString().startsWith(directory.uri.toString()) ||
        !file.uri.pathSegments.last.startsWith('material-')) {
      throw ArgumentError.value(material.path, 'material.path');
    }
    if (await file.exists()) await file.delete();
    if (await directory.exists() && await directory.list().isEmpty) {
      await directory.delete();
    }
  }

  Directory _problemDirectory(String slug) =>
      Directory.fromUri(supportDirectory.uri.resolve('materials/$slug/'));

  static Future<PlatformFile?> _pickFile(Set<String> extensions) async =>
      FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: extensions.toList()..sort(),
      );

  static String _basename(String value) =>
      value.replaceAll('\\', '/').split('/').last;

  static String _extension(String name) {
    final separator = name.lastIndexOf('.');
    if (separator <= 0 || separator == name.length - 1) {
      throw const FormatException('Material file has no extension');
    }
    return name.substring(separator + 1).toLowerCase();
  }

  static LearningMaterialKind _kind(String extension) {
    if (imageExtensions.contains(extension)) return LearningMaterialKind.image;
    if (markdownExtensions.contains(extension)) {
      return LearningMaterialKind.markdown;
    }
    if (textExtensions.contains(extension)) return LearningMaterialKind.text;
    if (pdfExtensions.contains(extension)) return LearningMaterialKind.pdf;
    if (videoExtensions.contains(extension)) return LearningMaterialKind.video;
    throw FormatException('Unsupported material format: .$extension');
  }

  static void _validateSize(int size, int limit) {
    if (size <= 0 || size > limit) {
      throw FormatException('Material must be between 1 byte and $limit bytes');
    }
  }

  static void _validateSlug(String slug) {
    if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(slug)) {
      throw ArgumentError.value(slug, 'problemSlug');
    }
  }
}
