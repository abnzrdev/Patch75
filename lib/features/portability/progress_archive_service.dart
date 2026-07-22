import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import '../../core/storage/app_state.dart';
import '../custom_tests/custom_test_case.dart';
import '../materials/learning_material.dart';
import '../review/review_models.dart';

enum ImportMode { merge, replace }

class ImportPreview {
  const ImportPreview({
    required this.exportedAtUtc,
    required this.problemCount,
    required this.materialCount,
    required this.totalBytes,
  });

  final DateTime exportedAtUtc;
  final int problemCount;
  final int materialCount;
  final int totalBytes;
}

class ProgressArchiveService {
  ProgressArchiveService({
    required this.supportDirectory,
    DateTime Function()? now,
    this.maxArchiveBytes = 512 * 1024 * 1024,
    this.maxEntryBytes = 256 * 1024 * 1024,
  }) : now = now ?? DateTime.now;

  static const schemaVersion = 1;
  static const maxEntries = 1000;
  final Directory supportDirectory;
  final DateTime Function() now;
  final int maxArchiveBytes;
  final int maxEntryBytes;

  Future<List<int>> export(
    AppState state, {
    bool includeMaterials = false,
    String appVersion = 'unknown',
    String originDeviceId = 'local',
  }) async {
    final archive = Archive();
    final files = <Map<String, Object?>>[];
    final exportedState = includeMaterials
        ? state
        : state.copyWith(materials: const {}, animationPaths: const {});
    _add(
      archive,
      files,
      'data/state.json',
      utf8.encode(jsonEncode(exportedState.toJson())),
    );

    if (includeMaterials) {
      for (final entry in state.materials.entries) {
        _validateSlug(entry.key);
        for (final material in entry.value) {
          final file = File(material.path);
          if (!await file.exists()) continue;
          final bytes = await file.readAsBytes();
          if (bytes.isEmpty || bytes.length > maxEntryBytes) {
            throw FormatException(
              'Material ${material.name} has an invalid size',
            );
          }
          final path =
              'materials/${entry.key}/${material.id}.${material.extension}';
          _validatePath(path);
          _add(archive, files, path, bytes);
        }
      }
    }

    final manifest = {
      'schemaVersion': schemaVersion,
      'appVersion': appVersion,
      'exportedAtUtc': now().toUtc().toIso8601String(),
      'originDeviceId': originDeviceId,
      'files': files,
    };
    archive.add(ArchiveFile.string('manifest.json', jsonEncode(manifest)));
    return ZipEncoder().encodeBytes(archive, modified: now().toUtc());
  }

  ImportPreview preview(List<int> bytes) {
    final decoded = _decode(bytes);
    final state = decoded.state;
    final slugs = <String>{
      ...state.drafts.keys.map((value) => value.split(':').first),
      ...state.notes.keys,
      ...state.progress.keys,
      ...state.reviewRecords.keys,
      ...state.customTests.keys,
      ...state.materials.keys,
    };
    return ImportPreview(
      exportedAtUtc: decoded.exportedAtUtc,
      problemCount: slugs.length,
      materialCount: decoded.materialEntries.length,
      totalBytes: bytes.length,
    );
  }

  Future<AppState> apply(
    List<int> bytes, {
    required AppState current,
    required ImportMode mode,
    Future<void> Function(AppState state)? persist,
  }) async {
    final decoded = _decode(bytes);
    final backup = Directory(
      '${supportDirectory.path}/backups/import-${now().toUtc().microsecondsSinceEpoch}',
    );
    await backup.create(recursive: true);
    await File(
      '${backup.path}/state.json',
    ).writeAsString(jsonEncode(current.toJson()), flush: true);
    final materialsRoot = Directory('${supportDirectory.path}/materials');
    if (await materialsRoot.exists()) {
      await _copyDirectory(
        materialsRoot,
        Directory('${backup.path}/materials'),
      );
    }

    try {
      final imported = await _restoreMaterials(decoded);
      final result = mode == ImportMode.replace
          ? imported
          : _merge(current, imported);
      await persist?.call(result);
      return result;
    } catch (_) {
      if (await materialsRoot.exists()) {
        await materialsRoot.delete(recursive: true);
      }
      final saved = Directory('${backup.path}/materials');
      if (await saved.exists()) await _copyDirectory(saved, materialsRoot);
      rethrow;
    }
  }

  void _add(
    Archive archive,
    List<Map<String, Object?>> files,
    String path,
    List<int> bytes,
  ) {
    archive.add(ArchiveFile.bytes(path, bytes));
    files.add({
      'path': path,
      'size': bytes.length,
      'sha256': sha256.convert(bytes).toString(),
    });
  }

  _DecodedArchive _decode(List<int> bytes) {
    if (bytes.isEmpty || bytes.length > maxArchiveBytes) {
      throw const FormatException('Progress archive size is not allowed');
    }
    try {
      final archive = ZipDecoder().decodeBytes(bytes, verify: true);
      if (archive.length > maxEntries) {
        throw const FormatException('Progress archive has too many files');
      }
      final entries = <String, List<int>>{};
      for (final entry in archive) {
        if (!entry.isFile || entry.isSymbolicLink) {
          throw const FormatException(
            'Archive links and directories are not allowed',
          );
        }
        _validatePath(entry.name);
        if (entry.size > maxEntryBytes || entries.containsKey(entry.name)) {
          throw const FormatException('Progress archive entry is not allowed');
        }
        entries[entry.name] = entry.readBytes()!;
      }
      final manifest = Map<String, Object?>.from(
        jsonDecode(utf8.decode(entries['manifest.json']!)) as Map,
      );
      if (manifest['schemaVersion'] != schemaVersion) {
        throw const FormatException('Unsupported progress archive version');
      }
      final listed = (manifest['files'] as List)
          .cast<Map>()
          .map((value) => Map<String, Object?>.from(value))
          .toList();
      final listedPaths = listed.map((value) => value['path']).toSet();
      if (listedPaths.length != listed.length ||
          !listedPaths.containsAll(
            entries.keys.where((key) => key != 'manifest.json'),
          ) ||
          entries.keys
              .where((key) => key != 'manifest.json')
              .any((key) => !listedPaths.contains(key))) {
        throw const FormatException(
          'Archive manifest does not match its files',
        );
      }
      for (final item in listed) {
        final path = item['path'] as String;
        final data = entries[path];
        if (data == null ||
            data.length != item['size'] ||
            sha256.convert(data).toString() != item['sha256']) {
          throw FormatException('Archive checksum failed for $path');
        }
      }
      final state = AppState.fromJson(
        Map<String, Object?>.from(
          jsonDecode(utf8.decode(entries['data/state.json']!)) as Map,
        ),
      );
      return _DecodedArchive(
        state,
        DateTime.parse(manifest['exportedAtUtc'] as String).toUtc(),
        entries..removeWhere((key, _) => !key.startsWith('materials/')),
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid or corrupt progress archive');
    }
  }

  Future<AppState> _restoreMaterials(_DecodedArchive decoded) async {
    final restored = <String, List<LearningMaterial>>{};
    for (final entry in decoded.state.materials.entries) {
      final items = <LearningMaterial>[];
      for (final material in entry.value) {
        final archivePath =
            'materials/${entry.key}/${material.id}.${material.extension}';
        final data = decoded.materialEntries[archivePath];
        if (data == null) continue;
        final directory = Directory(
          '${supportDirectory.path}/materials/${entry.key}',
        );
        await directory.create(recursive: true);
        final target = File(
          '${directory.path}/material-${material.id}.${material.extension}',
        );
        await target.writeAsBytes(data, flush: true);
        items.add(
          LearningMaterial(
            id: material.id,
            name: material.name,
            path: target.path,
            kind: material.kind,
            extension: material.extension,
            sizeBytes: data.length,
          ),
        );
      }
      if (items.isNotEmpty) restored[entry.key] = items;
    }
    return decoded.state.copyWith(materials: restored);
  }

  AppState _merge(AppState local, AppState remote) => local.copyWith(
    drafts: _mergeStamped(
      remote.drafts,
      local.drafts,
      remote.updatedAtUtc,
      local.updatedAtUtc,
      'draft:',
    ),
    notes: _mergeStamped(
      remote.notes,
      local.notes,
      remote.updatedAtUtc,
      local.updatedAtUtc,
      'note:',
    ),
    timerSeconds: {...remote.timerSeconds, ...local.timerSeconds},
    progress: {...remote.progress, ...local.progress},
    testHistory: {...remote.testHistory, ...local.testHistory},
    materials: _mergeMaterials(remote.materials, local.materials),
    reviewRecords: _mergeReviews(remote.reviewRecords, local.reviewRecords),
    reviewAttempts: {...remote.reviewAttempts, ...local.reviewAttempts},
    customTests: _mergeCustomTests(remote.customTests, local.customTests),
    settings: {...remote.settings, ...local.settings},
    updatedAtUtc: {...remote.updatedAtUtc, ...local.updatedAtUtc},
  );

  Map<String, T> _mergeStamped<T>(
    Map<String, T> remote,
    Map<String, T> local,
    Map<String, String> remoteTimes,
    Map<String, String> localTimes,
    String prefix,
  ) => {
    for (final key in {...remote.keys, ...local.keys})
      key: _remoteIsNewer(remoteTimes[prefix + key], localTimes[prefix + key])
          ? remote[key] as T
          : (local[key] ?? remote[key]) as T,
  };

  bool _remoteIsNewer(String? remote, String? local) =>
      remote != null &&
      (local == null || DateTime.parse(remote).isAfter(DateTime.parse(local)));

  Map<String, List<LearningMaterial>> _mergeMaterials(
    Map<String, List<LearningMaterial>> a,
    Map<String, List<LearningMaterial>> b,
  ) => {
    for (final slug in {...a.keys, ...b.keys})
      slug: {
        for (final item in [...?a[slug], ...?b[slug]]) item.id: item,
      }.values.toList(),
  };

  Map<String, List<CustomTestCase>> _mergeCustomTests(
    Map<String, List<CustomTestCase>> a,
    Map<String, List<CustomTestCase>> b,
  ) => {
    for (final slug in {...a.keys, ...b.keys})
      slug: _newestById([...?a[slug], ...?b[slug]]),
  };

  List<CustomTestCase> _newestById(List<CustomTestCase> values) {
    final result = <String, CustomTestCase>{};
    for (final value in values) {
      final old = result[value.id];
      if (old == null || value.updatedAtUtc.isAfter(old.updatedAtUtc)) {
        result[value.id] = value;
      }
    }
    return result.values.toList();
  }

  Map<String, ReviewRecord> _mergeReviews(
    Map<String, ReviewRecord> a,
    Map<String, ReviewRecord> b,
  ) => {
    for (final slug in {...a.keys, ...b.keys})
      slug: _mergeReview(a[slug], b[slug])!,
  };

  ReviewRecord? _mergeReview(ReviewRecord? a, ReviewRecord? b) {
    if (a == null) return b;
    if (b == null) return a;
    final newest = a.updatedAtUtc.isAfter(b.updatedAtUtc) ? a : b;
    final logs =
        {
            for (final log in [...a.logs, ...b.logs]) log.id: log,
          }.values.toList()
          ..sort((x, y) => x.reviewedAtUtc.compareTo(y.reviewedAtUtc));
    return newest.copyWith(logs: logs);
  }

  static void _validatePath(String path) {
    if (path.isEmpty ||
        path.startsWith('/') ||
        path.contains('\\') ||
        path
            .split('/')
            .any((part) => part.isEmpty || part == '.' || part == '..')) {
      throw FormatException('Unsafe archive path: $path');
    }
  }

  static void _validateSlug(String slug) {
    if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(slug)) {
      throw ArgumentError.value(slug, 'slug');
    }
  }

  static Future<void> _copyDirectory(Directory source, Directory target) async {
    await target.create(recursive: true);
    await for (final entity in source.list()) {
      final destination =
          '${target.path}/${entity.uri.pathSegments.where((value) => value.isNotEmpty).last}';
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(destination));
      }
      if (entity is File) await entity.copy(destination);
    }
  }
}

class _DecodedArchive {
  const _DecodedArchive(this.state, this.exportedAtUtc, this.materialEntries);
  final AppState state;
  final DateTime exportedAtUtc;
  final Map<String, List<int>> materialEntries;
}
