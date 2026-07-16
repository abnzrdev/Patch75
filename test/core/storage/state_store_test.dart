import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/core/storage/app_state.dart';
import 'package:offline_leetcode_trainer/core/storage/state_store.dart';

void main() {
  test('atomically saves and restores state', () async {
    final directory = await Directory.systemTemp.createTemp('olt-state-');
    addTearDown(() => directory.delete(recursive: true));
    final store = StateStore(directory);
    const state = AppState(notes: {'two-sum': 'hash map'});

    await store.save(state);

    expect(await store.load(), state);
    expect(File('${directory.path}/state.json.tmp').existsSync(), isFalse);
  });

  test('moves corrupt state aside and loads defaults', () async {
    final directory = await Directory.systemTemp.createTemp('olt-state-');
    addTearDown(() => directory.delete(recursive: true));
    await File('${directory.path}/state.json').writeAsString('{broken');
    final store = StateStore(directory);

    final state = await store.load();

    expect(state, const AppState());
    expect(
      directory.listSync().whereType<File>().any(
        (file) => file.path.contains('state.corrupt-'),
      ),
      isTrue,
    );
  });

  test('serializes repeated writes and keeps the latest state', () async {
    final directory = await Directory.systemTemp.createTemp('olt-state-');
    addTearDown(() => directory.delete(recursive: true));
    final store = StateStore(directory);

    await Future.wait([
      for (var seconds = 0; seconds < 50; seconds++)
        store.save(AppState(timerSeconds: {'two-sum': seconds})),
    ]);

    expect((await store.load()).timerSeconds['two-sum'], 49);
  });
}
