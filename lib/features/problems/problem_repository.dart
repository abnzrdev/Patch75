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
    final learning = Map<String, Object?>.from(
      jsonDecode(await bundle.loadString('assets/data/learning_metadata.json'))
          as Map,
    );
    return values.map((value) {
      final problem = Problem.fromJson(value as Map<String, Object?>);
      final metadata = learning[problem.slug];
      if (metadata is! Map) {
        throw FormatException('Missing learning metadata: ${problem.slug}');
      }
      return problem.withLearningMetadata(Map<String, Object?>.from(metadata));
    }).toList();
  }
}
