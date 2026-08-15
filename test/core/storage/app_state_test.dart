import 'package:flutter_test/flutter_test.dart';
import 'package:offline_leetcode_trainer/core/storage/app_state.dart';
import 'package:offline_leetcode_trainer/features/materials/learning_material.dart';
import 'package:offline_leetcode_trainer/features/review/fsrs_scheduler_service.dart';
import 'package:offline_leetcode_trainer/features/custom_tests/custom_test_case.dart';

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
    expect(state.materials, isEmpty);
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
      materials: {
        'two-sum': [
          LearningMaterial(
            id: 'material-1',
            name: 'notes.txt',
            path: '/private/material-1.txt',
            kind: LearningMaterialKind.text,
            extension: 'txt',
            sizeBytes: 12,
          ),
        ],
      },
      settings: {'compactMetadata': true},
      importedDataVersion: 1,
    );

    expect(AppState.fromJson(state.toJson()), state);
  });

  test('keeps materials isolated by problem', () {
    final state = AppState.fromJson({
      'materials': {
        'two-sum': [
          {
            'id': 'one',
            'name': 'one.pdf',
            'path': '/private/one.pdf',
            'kind': 'pdf',
            'extension': 'pdf',
            'sizeBytes': 10,
          },
        ],
        'three-sum': [
          {
            'id': 'two',
            'name': 'two.txt',
            'path': '/private/two.txt',
            'kind': 'text',
            'extension': 'txt',
            'sizeBytes': 20,
          },
        ],
      },
    });

    expect(state.materials['two-sum']!.single.id, 'one');
    expect(state.materials['three-sum']!.single.id, 'two');
  });

  test('round trips review records and keeps old solved progress', () async {
    final record = await FsrsSchedulerService().createCard(
      'two-sum',
      nowUtc: DateTime.utc(2026, 7, 22),
    );
    final state = AppState(
      progress: const {'two-sum': 'solved'},
      reviewRecords: {'two-sum': record},
    );

    final restored = AppState.fromJson(state.toJson());

    expect(restored.progress['two-sum'], 'solved');
    expect(restored.reviewRecords['two-sum'], record);
  });

  test('round trips custom tests per problem', () {
    final testCase = CustomTestCase.create(
      id: 'custom-two-sum-1',
      problemSlug: 'two-sum',
      name: 'edge',
      input: const {
        'nums': [8, 6],
        'target': 14,
      },
      nowUtc: DateTime.utc(2026, 7, 22),
    );
    final restored = AppState.fromJson(
      AppState(
        customTests: {
          'two-sum': [testCase],
        },
      ).toJson(),
    );

    expect(restored.customTests['two-sum'], [testCase]);
  });
}
