import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/materials/learning_material.dart';
import 'package:offline_leetcode_trainer/features/materials/local_material_store.dart';

void main() {
  late Directory root;
  late Directory support;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('olt-materials-');
    support = Directory('${root.path}/support');
  });

  tearDown(() async => root.delete(recursive: true));

  for (final extension in LocalMaterialStore.allowedExtensions) {
    test('imports .$extension into private problem storage', () async {
      final source = File('${root.path}/source.$extension');
      await source.writeAsBytes([1, 2, 3]);
      final store = LocalMaterialStore(
        supportDirectory: support,
        picker: (_) async =>
            PlatformFile(name: 'source.$extension', size: 3, path: source.path),
      );

      final material = await store.importForProblem('two-sum');

      expect(material, isNotNull);
      expect(material!.extension, extension);
      expect(
        File(material.path).parent.uri,
        Directory.fromUri(support.uri.resolve('materials/two-sum/')).uri,
      );
      expect(await File(material.path).readAsBytes(), [1, 2, 3]);
    });
  }

  test(
    'supports byte-backed picks and strips path components from names',
    () async {
      final store = LocalMaterialStore(
        supportDirectory: support,
        picker: (_) async => PlatformFile(
          name: r'../../folder\notes.txt',
          size: 4,
          bytes: Uint8List.fromList([1, 2, 3, 4]),
        ),
      );

      final material = await store.importForProblem('two-sum');

      expect(material!.name, 'notes.txt');
      expect(await File(material.path).length(), 4);
    },
  );

  test('returns null when picking is cancelled', () async {
    final store = LocalMaterialStore(
      supportDirectory: support,
      picker: (_) async => null,
    );
    expect(await store.importForProblem('two-sum'), isNull);
  });

  test('rejects blocked, extensionless, empty and oversized files', () async {
    Future<void> rejected(PlatformFile file) async {
      final store = LocalMaterialStore(
        supportDirectory: support,
        picker: (_) async => file,
      );
      await expectLater(
        store.importForProblem('two-sum'),
        throwsA(isA<FormatException>()),
      );
    }

    await rejected(
      PlatformFile(name: 'script.exe', size: 1, bytes: Uint8List(1)),
    );
    await rejected(PlatformFile(name: 'README', size: 1, bytes: Uint8List(1)));
    await rejected(
      PlatformFile(name: 'empty.txt', size: 0, bytes: Uint8List(0)),
    );
    await rejected(
      PlatformFile(
        name: 'huge.pdf',
        size: LocalMaterialStore.maxDocumentBytes + 1,
        bytes: Uint8List(1),
      ),
    );
    await rejected(
      PlatformFile(
        name: 'huge.mp4',
        size: LocalMaterialStore.maxVideoBytes + 1,
        bytes: Uint8List(1),
      ),
    );
  });

  test('validates actual source size and readable picker data', () async {
    final oversized = File('${root.path}/oversized.txt');
    await oversized.writeAsBytes(List.filled(8, 1));
    final mismatched = LocalMaterialStore(
      supportDirectory: support,
      documentLimitBytes: 4,
      picker: (_) async =>
          PlatformFile(name: 'oversized.txt', size: 4, path: oversized.path),
    );
    await expectLater(
      mismatched.importForProblem('two-sum'),
      throwsA(isA<FormatException>()),
    );

    final unreadable = LocalMaterialStore(
      supportDirectory: support,
      picker: (_) async => PlatformFile(name: 'missing.txt', size: 1),
    );
    await expectLater(
      unreadable.importForProblem('two-sum'),
      throwsA(isA<StateError>()),
    );
  });

  test('rejects unsafe slugs before opening the picker', () async {
    var picked = false;
    final store = LocalMaterialStore(
      supportDirectory: support,
      picker: (_) async {
        picked = true;
        return null;
      },
    );

    await expectLater(
      store.importForProblem('../two-sum'),
      throwsArgumentError,
    );
    expect(picked, isFalse);
  });

  test('replaces only after a valid import', () async {
    final old = File('${support.path}/materials/two-sum/material-old.gif');
    await old.parent.create(recursive: true);
    await old.writeAsBytes([1]);
    const existing = LearningMaterial(
      id: 'old',
      name: 'old.gif',
      path: '',
      kind: LearningMaterialKind.image,
      extension: 'gif',
      sizeBytes: 1,
    );
    Set<String>? requested;
    final store = LocalMaterialStore(
      supportDirectory: support,
      picker: (extensions) async {
        requested = extensions;
        return PlatformFile(
          name: 'new.png',
          size: 2,
          bytes: Uint8List.fromList([2, 3]),
        );
      },
    );
    final oldMaterial = LearningMaterial(
      id: existing.id,
      name: existing.name,
      path: old.path,
      kind: existing.kind,
      extension: existing.extension,
      sizeBytes: existing.sizeBytes,
    );

    final replacement = await store.importForProblem(
      'two-sum',
      replacing: oldMaterial,
    );

    expect(requested, LocalMaterialStore.allowedExtensions);
    expect(replacement!.path, isNot(old.path));
    expect(await old.exists(), isTrue);
  });

  test('deletes managed files but rejects paths outside storage', () async {
    final managed = File('${support.path}/materials/two-sum/material-one.txt');
    await managed.parent.create(recursive: true);
    await managed.writeAsString('safe');
    final store = LocalMaterialStore(
      supportDirectory: support,
      picker: (_) async => null,
    );
    final material = LearningMaterial(
      id: 'one',
      name: 'one.txt',
      path: managed.path,
      kind: LearningMaterialKind.text,
      extension: 'txt',
      sizeBytes: 4,
    );
    await store.delete(material, 'two-sum');
    expect(await managed.exists(), isFalse);

    final outside = File('${root.path}/outside.txt');
    await outside.writeAsString('keep');
    await expectLater(
      store.delete(
        LearningMaterial(
          id: 'outside',
          name: 'outside.txt',
          path: outside.path,
          kind: LearningMaterialKind.text,
          extension: 'txt',
          sizeBytes: 4,
        ),
        'two-sum',
      ),
      throwsArgumentError,
    );
    expect(await outside.exists(), isTrue);
  });
}
