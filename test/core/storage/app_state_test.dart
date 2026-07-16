import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/core/storage/app_state.dart';

void main() {
  test('loads defaults for missing fields and migrates version one', () {
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
  });

  test('round trips persisted workspace state', () {
    const state = AppState(
      selectedProblemSlug: 'two-sum',
      drafts: {'two-sum:python': 'pass'},
      notes: {'two-sum': 'Use a map'},
      timerSeconds: {'two-sum': 42},
      focusMode: true,
      progress: {'two-sum': 'solved'},
    );

    expect(AppState.fromJson(state.toJson()), state);
  });
}
