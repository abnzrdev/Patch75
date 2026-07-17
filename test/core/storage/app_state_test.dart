import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/core/storage/app_state.dart';

void main() {
  test('loads defaults for missing fields and migrates old state', () {
    final state = AppState.fromJson({
      'schemaVersion': 1,
      'selectedProblem': 'two-sum',
      'drafts': {'two-sum:python': 'pass'},
    });

    expect(state.schemaVersion, AppState.currentSchemaVersion);
    expect(state.selectedProblemSlug, 'two-sum');
    expect(state.drafts['two-sum:python'], 'pass');
    expect(state.notes, isEmpty);
    expect(state.timerSeconds, isEmpty);
    expect(state.testHistory, isEmpty);
    expect(state.animationPaths, isEmpty);
    expect(state.importedDataVersion, 1);
  });

  test('round trips persisted workspace state', () {
    const state = AppState(
      selectedProblemSlug: 'two-sum',
      drafts: {'two-sum:python': 'pass'},
      notes: {'two-sum': 'Use a map'},
      timerSeconds: {'two-sum': 42},
      focusMode: true,
      progress: {'two-sum': 'solved'},
      testHistory: {
        'two-sum': ['passed:3/3'],
      },
      animationPaths: {'two-sum': '/private/animation.gif'},
      settings: {'compactMetadata': true},
      importedDataVersion: 1,
    );

    expect(AppState.fromJson(state.toJson()), state);
  });
}
