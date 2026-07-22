class Problem {
  Problem({
    required this.id,
    required this.slug,
    required this.title,
    required this.difficulty,
    required this.topics,
    required this.description,
    required this.examples,
    required this.constraints,
    required this.starterCodeByLanguage,
    required this.testCases,
    required this.source,
    required this.sourceUrl,
    this.hints = const [],
    this.expectedTimeComplexity = '',
    this.expectedSpaceComplexity = '',
    this.complexityExplanation = '',
  });

  factory Problem.fromJson(Map<String, Object?> json) {
    final slug = json['slug'] as String;
    if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(slug)) {
      throw const FormatException('Invalid problem slug');
    }
    return Problem(
      id: json['id'] as int,
      slug: slug,
      title: json['title'] as String,
      difficulty: json['difficulty'] as String,
      topics: List<String>.from(json['topics'] as List),
      description: json['description'] as String,
      examples: (json['examples'] as List)
          .map(
            (value) => ProblemExample.fromJson(value as Map<String, Object?>),
          )
          .toList(),
      constraints: List<String>.from(json['constraints'] as List),
      starterCodeByLanguage: Map<String, String>.from(
        json['starterCodeByLanguage'] as Map,
      ),
      testCases: (json['testCases'] as List)
          .map(
            (value) => ProblemTestCase.fromJson(value as Map<String, Object?>),
          )
          .toList(),
      source: json['source'] as String,
      sourceUrl: json['sourceUrl'] as String,
      hints: List<String>.from(json['hints'] as List? ?? const []),
      expectedTimeComplexity: json['expectedTimeComplexity'] as String? ?? '',
      expectedSpaceComplexity: json['expectedSpaceComplexity'] as String? ?? '',
      complexityExplanation: json['complexityExplanation'] as String? ?? '',
    );
  }

  final int id;
  final String slug;
  final String title;
  final String difficulty;
  final List<String> topics;
  final String description;
  final List<ProblemExample> examples;
  final List<String> constraints;
  final Map<String, String> starterCodeByLanguage;
  final List<ProblemTestCase> testCases;
  final String source;
  final String sourceUrl;
  final List<String> hints;
  final String expectedTimeComplexity;
  final String expectedSpaceComplexity;
  final String complexityExplanation;

  Problem withLearningMetadata(Map<String, Object?> metadata) => Problem(
    id: id,
    slug: slug,
    title: title,
    difficulty: difficulty,
    topics: topics,
    description: description,
    examples: examples,
    constraints: constraints,
    starterCodeByLanguage: starterCodeByLanguage,
    testCases: testCases,
    source: source,
    sourceUrl: sourceUrl,
    hints: List<String>.from(metadata['hints'] as List),
    expectedTimeComplexity: metadata['time'] as String,
    expectedSpaceComplexity: metadata['space'] as String,
    complexityExplanation: metadata['explanation'] as String,
  );

  Map<String, Type> get inputFieldTypes {
    if (testCases.isEmpty) return const {};
    return testCases.first.input.map(
      (key, value) => MapEntry(key, switch (value) {
        int() => int,
        double() => double,
        String() => String,
        bool() => bool,
        List() => List,
        Map() => Map,
        _ => Object,
      }),
    );
  }
}

class ProblemExample {
  const ProblemExample({
    required this.input,
    required this.output,
    this.explanation,
  });

  factory ProblemExample.fromJson(Map<String, Object?> json) => ProblemExample(
    input: json['input'] as String,
    output: json['output'] as String,
    explanation: json['explanation'] as String?,
  );

  final String input;
  final String output;
  final String? explanation;
}

class ProblemTestCase {
  const ProblemTestCase({
    required this.id,
    required this.input,
    required this.expected,
    required this.sample,
  });

  factory ProblemTestCase.fromJson(Map<String, Object?> json) =>
      ProblemTestCase(
        id: json['id'] as String,
        input: Map<String, Object?>.from(json['input'] as Map),
        expected: json['expected'],
        sample: json['sample'] as bool? ?? false,
      );

  final String id;
  final Map<String, Object?> input;
  final Object? expected;
  final bool sample;
}
