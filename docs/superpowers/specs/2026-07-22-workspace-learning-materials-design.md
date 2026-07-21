# Workspace Learning Materials Design

## Scope

Improve the existing Flutter workspace without changing judge requests, Cojudge execution, problem navigation, saved drafts, or submit behavior. Reuse `OltColors`, `OltPanel`, `OltButton`, `AppController`, `AppState`, `StateStore`, `re_editor`, `file_picker`, and application-support storage. Do not edit generated platform files or the Flutter SDK.

## Visual acceptance rules

- Preserve the black/dark-green terminal surface, square borders, monospace typography, and lime signal color.
- Problem body text uses a readable secondary foreground color with at least 4.5:1 contrast; titles, section labels, examples, constraints, and inline code have distinct size, weight, color, spacing, or surface treatment.
- Long problem content scrolls to its final constraint without overflow.
- Python keywords, classes, functions, built-in types, strings, numbers, comments, and operators are visually distinct while selection, cursor, indentation, line numbers, scrolling, drafts, and judge integration continue through `re_editor`.
- Code and notes editing surfaces fill their panels and begin at the top-left. Notes have visible padding, multiline scrolling, selection, cursor movement, a useful empty-state hint, and a live character count.
- Panel headers, borders, buttons, focus/active states, result rows, and spacing use shared OLT tokens. Interactive touch targets are at least 44 logical pixels.
- At widths below the established compact breakpoint, the five-destination workspace remains overflow-free in Android portrait and landscape. Desktop columns remain usable in smaller windows and use available space on wide screens.

## Problem presentation

Keep `Problem` data unchanged. Replace the uniform description block with a small presentation widget that recognizes paragraph breaks and backtick-delimited inline code, then renders examples and constraints as separate, labeled groups. This is display-only; it does not reinterpret judge data or download content.

## Python editor

Use `re_editor`'s existing pattern-matching syntax-highlighting API rather than replacing the editor. A focused Python highlighter owns ordered patterns and OLT text styles. Highlighting must not modify controller text or input handling, so Android IME composition remains native to the existing editor.

## Notes

Retain `AppState.notes` and `AppController.updateNotes`, preserving all existing persisted notes without a schema migration. Use one shared notes widget in desktop and compact layouts. It is top-aligned, expands to the panel, has 12 logical pixels of content padding, and displays the current character count outside the editable area. Switching problems updates the same controller from the selected problem's existing note.

## Private learning materials

Generalize `LocalAnimationStore` into a per-problem local-material store while retaining compatibility with existing `animationPaths`. Existing animation paths migrate into the attachment model on load or first access without moving or deleting the original file until the new state has been saved successfully.

Each attachment records a stable ID, original filename, stored private path, media kind, extension/MIME description, and byte size. Files live below the platform application-support directory in `materials/<safe-problem-slug>/`. Stored filenames are generated internally; original filenames are metadata only and never participate in path construction.

Allowed types are GIF, WebP, PNG, JPEG, PDF, Markdown, TXT, MP4, and WebM. Validate the lowercase extension, positive declared and actual byte sizes, readable source data, safe problem slug, and maximum size before finalizing an atomic copy. Images/documents use a 64 MiB ceiling; videos use a 256 MiB ceiling. Failed imports leave current attachments intact and remove temporary files.

The attachment list shows original filename, friendly type, formatted size, and `OPEN`, `REPLACE`, and `REMOVE` actions. `Import Animation` filters to image/animation types; `Add Material` accepts all allowed types. Replace imports a validated new file first, updates persisted state, then removes the superseded managed copy. Remove deletes only a validated managed path after state is updated. Missing and corrupt files remain listed with a clear unavailable state and recoverable replace/remove actions.

Images and animated images render inside the existing viewer. Markdown is rendered inside the app using a small established package; plain text uses a selectable scrolling view. No network image or link fetching is performed. PDF and video use a maintained cross-platform native file-opening package that supports Android content sharing/URI handling and desktop shell integration; failures or unsupported platforms produce an in-app error with the filename. No `file:` URL assumption is used. Embedded video and PDF engines are deliberately omitted unless platform smoke tests prove an already-installed capability reliable.

The UI states that users should import only files they created or have permission to use. The application never downloads media from GitHub or external websites.

## State and data flow

`AppState` gains a backward-compatible per-problem attachment map and increments its schema version. Missing fields deserialize to empty collections. `AppController` exposes attachments for the current slug and coordinates import, replace, open, and remove operations through the store. State writes continue through the existing serialized `StateStore`; drafts, notes, timers, progress, history, and animation paths remain readable.

The store performs path and file operations; the controller owns user-visible busy/error state; workspace widgets only render state and invoke controller actions. Judge classes and request construction are unchanged.

## Error handling and safety

- Reject path traversal, invalid slugs, unsupported/extensionless files, zero-byte files, oversized files, missing picker data, and unreadable sources.
- Resolve and verify every managed target remains beneath the expected application-support problem directory before replacement or deletion.
- Copy to a temporary file, verify it, rename atomically, persist state, and only then remove an older managed file.
- Surface cancellation silently and actionable failures in the material panel.
- Preserve unrelated untracked files, existing `.backups`, `.logs`, and diagnostics. Back up each tracked file before its first edit and keep backups ignored/uncommitted.

## Testing and validation

Add focused unit/widget coverage for all Python token categories, editor and notes top-left alignment, notes persistence per problem, existing-note migration, attachment import/reopen/replace/remove, allowed and blocked types, size limits, safe slug/filename/path handling, legacy animation persistence, missing/corrupt files, workspace actions, desktop and Android-sized overflow, and unchanged Run Tests/Submit behavior.

Before the single feature commit, run `dart format .`, `flutter pub get`, `flutter analyze`, the full `flutter test`, `flutter build linux --debug`, and `flutter build apk --debug`. Launch Linux for a manual workspace smoke test. Install and run on Android device `R9ZX30B0CHB`; verify navigation, IME code input, highlighting, notes persistence, picker/import/reopen/replace/remove, portrait/landscape layout, and Run Tests while capturing relevant `adb logcat` Flutter errors.

Add a GitHub Actions workflow on `windows-latest` that enables Windows desktop, gets dependencies, checks formatting, analyzes, runs all Flutter tests, and builds Windows debug. Report Windows as pending until the workflow itself completes successfully; never infer Windows success from Linux.

## Commit boundary

Commit only source, tests, dependency lockfile changes, documentation, ignore rules, and the Windows workflow required by this feature, after all locally available validation passes. Use `feat(workspace): improve editor and local learning materials`. Do not commit backups, logs, generated builds, or private imported materials.
