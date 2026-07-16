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
    final index =
        jsonDecode(await bundle.loadString('assets/data/index/blind75.json'))
            as Map<String, Object?>;
    final entries = index['problems'] as List;
    return Future.wait([
      for (final entry in entries)
        _load((entry as Map<String, Object?>)['slug'] as String),
    ]);
  }

  Future<Problem> _load(String slug) async => Problem.fromJson(
    jsonDecode(await bundle.loadString('assets/data/problems/$slug.json'))
        as Map<String, Object?>,
  );
}
