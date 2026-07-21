enum LearningMaterialKind { image, markdown, text, pdf, video }

class LearningMaterial {
  const LearningMaterial({
    required this.id,
    required this.name,
    required this.path,
    required this.kind,
    required this.extension,
    required this.sizeBytes,
  });

  factory LearningMaterial.fromJson(Map<String, Object?> json) =>
      LearningMaterial(
        id: json['id'] as String,
        name: json['name'] as String,
        path: json['path'] as String,
        kind: LearningMaterialKind.values.byName(json['kind'] as String),
        extension: json['extension'] as String,
        sizeBytes: json['sizeBytes'] as int,
      );

  final String id;
  final String name;
  final String path;
  final LearningMaterialKind kind;
  final String extension;
  final int sizeBytes;

  bool get isImage => kind == LearningMaterialKind.image;

  String get friendlyType => switch (kind) {
    LearningMaterialKind.image => '${extension.toUpperCase()} IMAGE',
    LearningMaterialKind.markdown => 'MARKDOWN',
    LearningMaterialKind.text => 'TEXT',
    LearningMaterialKind.pdf => 'PDF',
    LearningMaterialKind.video => '${extension.toUpperCase()} VIDEO',
  };

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'kind': kind.name,
    'extension': extension,
    'sizeBytes': sizeBytes,
  };

  @override
  bool operator ==(Object other) =>
      other is LearningMaterial &&
      id == other.id &&
      name == other.name &&
      path == other.path &&
      kind == other.kind &&
      extension == other.extension &&
      sizeBytes == other.sizeBytes;

  @override
  int get hashCode => Object.hash(id, name, path, kind, extension, sizeBytes);
}
