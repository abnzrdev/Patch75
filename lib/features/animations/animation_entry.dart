class AnimationEntry {
  const AnimationEntry({
    required this.problemId,
    required this.slug,
    required this.title,
    required this.relativePath,
    required this.sourceUrl,
  });

  factory AnimationEntry.fromJson(Map<String, Object?> json) => AnimationEntry(
    problemId: json['problemId'] as int,
    slug: json['slug'] as String,
    title: json['title'] as String,
    relativePath: json['relativePath'] as String?,
    sourceUrl: json['sourceUrl'] as String,
  );

  final int problemId;
  final String slug;
  final String title;
  final String? relativePath;
  final String sourceUrl;

  bool matches({required int id, required String slug, required String title}) {
    if (problemId == id) return true;
    return _normalize(this.slug) == _normalize(slug) ||
        _normalize(this.title) == _normalize(title);
  }
}

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-|-$'), '');
