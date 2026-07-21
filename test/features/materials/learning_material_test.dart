import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/materials/learning_material.dart';

void main() {
  test('round trips material metadata', () {
    const material = LearningMaterial(
      id: 'material-1',
      name: 'walkthrough.MD',
      path: '/private/material-1.md',
      kind: LearningMaterialKind.markdown,
      extension: 'md',
      sizeBytes: 1200,
    );

    expect(LearningMaterial.fromJson(material.toJson()), material);
    expect(material.friendlyType, 'MARKDOWN');
    expect(material.isImage, isFalse);
  });

  test('identifies image materials', () {
    const material = LearningMaterial(
      id: 'material-2',
      name: 'trace.gif',
      path: '/private/material-2.gif',
      kind: LearningMaterialKind.image,
      extension: 'gif',
      sizeBytes: 42,
    );

    expect(material.isImage, isTrue);
    expect(material.friendlyType, 'GIF IMAGE');
  });
}
