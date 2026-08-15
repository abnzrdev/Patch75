import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/core/storage/app_state.dart';
import 'package:offline_leetcode_trainer/features/materials/learning_material.dart';
import 'package:offline_leetcode_trainer/features/portability/progress_archive_service.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('olt-archive-test-');
  });

  tearDown(() => directory.delete(recursive: true));

  test(
    'exports, previews, and replaces progress with private materials',
    () async {
      final source = File('${directory.path}/source.png');
      await source.writeAsBytes([1, 2, 3]);
      final state = AppState(
        notes: const {'two-sum': 'remember the complement'},
        materials: {
          'two-sum': [
            LearningMaterial(
              id: 'image-1',
              name: 'diagram.png',
              path: source.path,
              kind: LearningMaterialKind.image,
              extension: 'png',
              sizeBytes: 3,
            ),
          ],
        },
      );
      final service = ProgressArchiveService(
        supportDirectory: Directory('${directory.path}/app'),
        now: () => DateTime.utc(2026, 7, 22),
      );

      final bytes = await service.export(state, includeMaterials: true);
      final preview = service.preview(bytes);
      final imported = await service.apply(
        bytes,
        current: const AppState(),
        mode: ImportMode.replace,
      );

      expect(preview.problemCount, 1);
      expect(preview.materialCount, 1);
      expect(imported.notes['two-sum'], 'remember the complement');
      final material = imported.materials['two-sum']!.single;
      expect(material.path, contains('/materials/two-sum/'));
      expect(await File(material.path).readAsBytes(), [1, 2, 3]);
    },
  );

  test('merge keeps local scalar data and combines per-problem maps', () async {
    final service = ProgressArchiveService(supportDirectory: directory);
    final bytes = await service.export(
      const AppState(
        drafts: {'two-sum:python': 'remote'},
        notes: {'valid-parentheses': 'remote note'},
      ),
    );

    final merged = await service.apply(
      bytes,
      current: const AppState(
        drafts: {'two-sum:python': 'local'},
        notes: {'two-sum': 'local note'},
      ),
      mode: ImportMode.merge,
    );

    expect(merged.drafts['two-sum:python'], 'local');
    expect(merged.notes, {
      'valid-parentheses': 'remote note',
      'two-sum': 'local note',
    });
  });

  test('merge uses the newest timestamp for mutable records', () async {
    final service = ProgressArchiveService(supportDirectory: directory);
    final bytes = await service.export(
      const AppState(
        notes: {'two-sum': 'remote'},
        updatedAtUtc: {'note:two-sum': '2026-07-22T12:00:00.000Z'},
      ),
    );
    final merged = await service.apply(
      bytes,
      current: const AppState(
        notes: {'two-sum': 'local'},
        updatedAtUtc: {'note:two-sum': '2026-07-21T12:00:00.000Z'},
      ),
      mode: ImportMode.merge,
    );
    expect(merged.notes['two-sum'], 'remote');
  });

  test('rolls material files back when persistence fails', () async {
    final appDirectory = Directory('${directory.path}/app');
    final old = File('${appDirectory.path}/materials/two-sum/material-old.png');
    await old.create(recursive: true);
    await old.writeAsBytes([9]);
    final source = File('${directory.path}/new.png')..writeAsBytesSync([1]);
    final archive = await ProgressArchiveService(supportDirectory: appDirectory)
        .export(
          AppState(
            materials: {
              'two-sum': [
                LearningMaterial(
                  id: 'new',
                  name: 'new.png',
                  path: source.path,
                  kind: LearningMaterialKind.image,
                  extension: 'png',
                  sizeBytes: 1,
                ),
              ],
            },
          ),
          includeMaterials: true,
        );

    await expectLater(
      ProgressArchiveService(supportDirectory: appDirectory).apply(
        archive,
        current: const AppState(),
        mode: ImportMode.replace,
        persist: (_) => throw StateError('disk full'),
      ),
      throwsStateError,
    );
    expect(await old.readAsBytes(), [9]);
    expect(
      File(
        '${appDirectory.path}/materials/two-sum/material-new.png',
      ).existsSync(),
      isFalse,
    );
  });

  test('rejects corrupt archives and zip-slip paths', () async {
    final service = ProgressArchiveService(supportDirectory: directory);
    expect(() => service.preview([1, 2, 3]), throwsFormatException);
    final bytes = await service.export(const AppState());
    final damaged = [...bytes]..[bytes.length ~/ 2] ^= 0xff;
    expect(() => service.preview(damaged), throwsFormatException);
  });

  test('rejects archives above configured size limit', () async {
    final service = ProgressArchiveService(
      supportDirectory: directory,
      maxArchiveBytes: 2,
    );
    expect(() => service.preview([1, 2, 3]), throwsFormatException);
  });

  test('rejects cumulative expanded data above configured limit', () async {
    final exporter = ProgressArchiveService(supportDirectory: directory);
    final bytes = await exporter.export(
      AppState(
        drafts: {'two-sum:python': List.filled(200, 'x').join()},
        notes: {'two-sum': List.filled(200, 'y').join()},
      ),
    );
    final service = ProgressArchiveService(
      supportDirectory: directory,
      maxArchiveBytes: bytes.length + 1,
      maxEntryBytes: 4096,
      maxExpandedBytes: 100,
    );

    expect(() => service.preview(bytes), throwsFormatException);
  });
}
