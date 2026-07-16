import 'dart:convert';

import 'package:flutter/services.dart';

import 'problem.dart';

abstract interface class ProblemRepository {
  Future<List<Problem>> loadAll();
}

class AssetProblemRepository implements ProblemRepository {
  const AssetProblemRepository(this.bundle);

  final AssetBundle bundle;

  @override
  Future<List<Problem>> loadAll() async {
    final values =
        jsonDecode(
              await bundle.loadString('assets/data/index/all_problems.json'),
            )
            as List;
    return values
        .map((value) => Problem.fromJson(value as Map<String, Object?>))
        .toList();
  }
}
