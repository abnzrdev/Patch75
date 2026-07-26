import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/animations/local_animation_store.dart';

void main() {
  late Directory temporaryDirectory;
  late Directory supportDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'olt-animation-test-',
    );

    supportDirectory = Directory(
      '${temporaryDirectory.path}/application-support',
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('copies an animation into private problem storage', () async {
    final source = File('${temporaryDirectory.path}/source.gif');

    await source.writeAsBytes(<int>[71, 73, 70, 56, 57, 97]);

    final store = LocalAnimationStore(
      supportDirectory: supportDirectory,
      picker: () async => PlatformFile(
        name: 'demo.GIF',
        size: await source.length(),
        path: source.path,
      ),
    );

    final importedPath = await store.importForProblem('two-sum');

    expect(importedPath, isNotNull);
    expect(
      File(importedPath!).parent.uri,
      Directory.fromUri(
        supportDirectory.uri.resolve('animations/two-sum/'),
      ).uri,
    );
    expect(importedPath, endsWith('.gif'));

    expect(await File(importedPath).readAsBytes(), await source.readAsBytes());
  });

  test('returns null when selection is cancelled', () async {
    final store = LocalAnimationStore(
      supportDirectory: supportDirectory,
      picker: () async => null,
    );

    expect(await store.importForProblem('two-sum'), isNull);
  });

  test('rejects unsupported formats', () async {
    final source = File('${temporaryDirectory.path}/animation.txt');

    await source.writeAsString('not an image');

    final store = LocalAnimationStore(
      supportDirectory: supportDirectory,
      picker: () async => PlatformFile(
        name: 'animation.txt',
        size: await source.length(),
        path: source.path,
      ),
    );

    expect(store.importForProblem('two-sum'), throwsA(isA<FormatException>()));
  });

  test('rejects unsafe problem slugs', () async {
    final store = LocalAnimationStore(
      supportDirectory: supportDirectory,
      picker: () async => null,
    );

    expect(store.importForProblem('../two-sum'), throwsArgumentError);
  });

  test('replaces an older animation format', () async {
    final oldFile = File(
      '${supportDirectory.path}/animations/'
      'two-sum/animation.png',
    );

    await oldFile.parent.create(recursive: true);
    await oldFile.writeAsBytes(<int>[1, 2, 3]);

    final source = File('${temporaryDirectory.path}/replacement.gif');

    await source.writeAsBytes(<int>[71, 73, 70, 56, 57, 97]);

    final store = LocalAnimationStore(
      supportDirectory: supportDirectory,
      picker: () async => PlatformFile(
        name: 'replacement.gif',
        size: await source.length(),
        path: source.path,
      ),
    );

    final importedPath = await store.importForProblem('two-sum');

    expect(await oldFile.exists(), isFalse);
    expect(await File(importedPath!).exists(), isTrue);
  });

  test('removes the private animation copy', () async {
    final animation = File(
      '${supportDirectory.path}/animations/'
      'two-sum/animation-123.gif',
    );

    await animation.parent.create(recursive: true);
    await animation.writeAsBytes(<int>[1, 2, 3]);

    final store = LocalAnimationStore(
      supportDirectory: supportDirectory,
      picker: () async => null,
    );

    await store.removeForProblem('two-sum');

    expect(await animation.exists(), isFalse);
    expect(await animation.parent.exists(), isFalse);
  });
}
