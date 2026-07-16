abstract interface class DraftRepository {
  Future<String?> loadDraft(String problemSlug, String language);
  Future<void> saveDraft(
    String problemSlug,
    String language,
    String sourceCode,
  );
}

abstract interface class NotesRepository {
  Future<String?> loadNotes(String problemSlug);
  Future<void> saveNotes(String problemSlug, String notes);
}

abstract interface class ProgressRepository {
  Future<String?> loadProgress(String problemSlug);
  Future<void> saveProgress(String problemSlug, String state);
}
