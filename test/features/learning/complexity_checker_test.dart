import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/features/learning/complexity_checker.dart';

void main() {
  test('normalizes harmless Big O formatting differences', () {
    expect(normalizeComplexity(' o ( N ^ 2 ) '), 'O(n²)');
    expect(normalizeComplexity('O(n * log N)'), 'O(n·logn)');
    expect(normalizeComplexity('O(V + E)'), 'O(v+e)');
  });

  test('compares exact, partial, and different answers', () {
    expect(
      compareComplexity('O(n)', 'O(n)', 'O(1)', 'O(1)').status,
      ComplexityStatus.correct,
    );
    expect(
      compareComplexity('O(n)', 'O(n)', 'O(n)', 'O(1)').status,
      ComplexityStatus.partiallyCorrect,
    );
    expect(
      compareComplexity('O(n²)', 'O(n)', 'O(n)', 'O(1)').status,
      ComplexityStatus.different,
    );
  });
}
