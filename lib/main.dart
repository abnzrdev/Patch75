import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app_controller.dart';
import 'app/offline_trainer_app.dart';
import 'core/storage/state_store.dart';
import 'features/problems/problem.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final problem = Problem.fromJson(
    jsonDecode(await rootBundle.loadString('assets/data/problems/two-sum.json'))
        as Map<String, Object?>,
  );
  final store = StateStore(await getApplicationSupportDirectory());
  runApp(
    OfflineTrainerApp(
      controller: AppController(
        problem: problem,
        state: await store.load(),
        onSave: store.save,
      ),
    ),
  );
}
