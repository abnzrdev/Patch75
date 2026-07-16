import 'dart:convert';
import 'dart:io';

import 'app_state.dart';

class StateStore {
  StateStore(this.directory);

  final Directory directory;

  File get _file => File('${directory.path}/state.json');

  Future<AppState> load() async {
    try {
      if (!await _file.exists()) return const AppState();
      return AppState.fromJson(
        jsonDecode(await _file.readAsString()) as Map<String, Object?>,
      );
    } on Object {
      if (await _file.exists()) {
        final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
        await _file.rename('${directory.path}/state.corrupt-$timestamp.json');
      }
      return const AppState();
    }
  }

  Future<void> save(AppState state) async {
    await directory.create(recursive: true);
    final temporary = File('${_file.path}.tmp');
    await temporary.writeAsString(jsonEncode(state.toJson()), flush: true);
    await temporary.rename(_file.path);
  }
}
