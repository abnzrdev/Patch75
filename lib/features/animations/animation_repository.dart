import 'dart:convert';

import 'package:flutter/services.dart';

import 'animation_entry.dart';

abstract interface class AnimationRepository {
  Future<List<AnimationEntry>> loadAll();
}

class AssetAnimationRepository implements AnimationRepository {
  const AssetAnimationRepository(this.bundle);

  final AssetBundle bundle;

  @override
  Future<List<AnimationEntry>> loadAll() async {
    final values =
        jsonDecode(await bundle.loadString('assets/data/animation_index.json'))
            as List;
    return values
        .map((value) => AnimationEntry.fromJson(value as Map<String, Object?>))
        .toList();
  }
}
