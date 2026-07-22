# Offline LeetCode Trainer Architecture

## Scope

Offline LeetCode Trainer is a local-first Flutter application for studying and
solving Blind 75 problems. Browsing, editing, notes, progress, timers, and
imported animations work without a network connection. Code execution is an
optional platform capability: Docker via a localhost bridge on desktop and an
embedded Python runtime on Android.

Accounts, cloud sync, analytics, social features, and a remote judge are outside
this release. FSRS scheduling and ZIP portability are private local features.

## Structure

```text
lib/
  app/                 composition root and adaptive shell
  core/
    design/            micrographic tokens and primitives
    storage/           versioned JSON store and atomic file adapter
    platform/          platform selection and lifecycle adapters
    widgets/           shared accessible widgets
  features/
    problems/          models, import schema, repository, browser
    workspace/         editor, session state, responsive workspace
    judge/             requests, results, validators, platform services
    animations/        manifest matching and local viewer
    notes/             note repository and editor
    progress/          attempts, solved state, history
    review/            FSRS cards, attempts, queue, history
    learning/          hints and complexity self-checks
    custom_tests/      per-problem user test inputs
    portability/       validated progress ZIP export/import and sharing
    settings/          persisted app preferences
```

This is feature-based without use-case/entity layering. Models and repository
interfaces live with the feature that owns them. The app composition root wires
concrete local implementations into widgets.

## Required boundaries

- `ProblemRepository`: lists, filters, and loads normalized bundled problems.
- `AnimationRepository`: matches problem ID, normalized slug, then normalized
  title; it returns local availability separately from manifest metadata.
- `JudgeService`: reports availability and runs a validated `JudgeRequest`.
- `NotesRepository`: loads and saves per-problem plain-text notes.
- `ProgressRepository`: loads and saves attempted/solved state and test history.
- `DraftRepository`: loads and saves source by problem and language.

Widgets never invoke Docker, shell commands, platform channels, or raw file
paths. They consume these interfaces through a small `AppController`.

## Data

Generated problem JSON is bundled under `assets/data/problems/`; the Blind 75
index is under `assets/data/index/`. Each record contains:

```json
{
  "id": 1,
  "slug": "two-sum",
  "title": "Two Sum",
  "difficulty": "easy",
  "topics": ["array", "hash-table"],
  "description": "…",
  "examples": [],
  "constraints": [],
  "starterCodeByLanguage": {"python": "…"},
  "testCases": [],
  "source": "cojudge",
  "sourceUrl": "https://github.com/cojudge/cojudge"
}
```

Runtime state is one versioned JSON document in the application-support
directory. Writes use a sibling temporary file followed by rename. Invalid JSON
is moved aside and defaults are loaded. The document stores selected problem,
drafts, notes, timers, focus preference, progress, test history, settings, and
the imported-data version, review records, review attempts, custom tests,
learning materials, and mutation timestamps. This avoids a database dependency
for a bounded set of 75 records.

## Judge flow

```text
Workspace → JudgeService → DesktopCojudgeJudgeService → 127.0.0.1 bridge → Docker
                         → AndroidPythonJudgeService → MethodChannel → Python
                         → UnsupportedJudgeService → explicit unavailable result
```

`JudgeRequest` contains only `problemSlug`, `language`, `sourceCode`, and
`selectedTests`. Validation enforces allowlists, source and input limits, and
rejects traversal before platform code receives a request. `JudgeResult`
contains status, bounded stdout/stderr, execution time, optional memory use,
counts, and individual test results.

The desktop bridge binds only to `127.0.0.1`, accepts bounded JSON, uses
argument arrays, creates mode-0700 temporary directories, and starts
unprivileged containers with no network, no capabilities, a read-only root,
memory/PID/CPU limits, and no host mounts other than the temporary submission.

Chaquopy runs Python 3.11 in a separate Android service process. It is not a
security sandbox: Python has the service process's app UID and a timeout cannot
reliably stop native/interpreter work in-process. The service has no exported
components or permissions and is killed/recreated after a timeout.

## UI

The design uses near-black/off-white plus one lime signal color, a 4 px grid,
hairline borders, square corners, monospaced text, visible coordinates,
registration marks, and dimension lines. Decorative metadata may be 8–10 px;
problem text and controls use accessible sizes. Focus outlines, semantics,
minimum 44 px touch targets, text scaling, and overflow handling are mandatory.

At 900 logical pixels or wider the workspace is problem/editor/right-pane.
Focus mode removes the right pane. Below 900 it switches to five destinations:
Problem, Code, Results, Materials, and Notes. No desktop columns are squeezed
onto a handset.

## Lifecycle and errors

The timer uses monotonic elapsed intervals while active. Lifecycle pause saves
and stops accrual; resume restarts it. Draft and notes writes are debounced, but
explicit navigation and lifecycle changes flush immediately.

Missing Docker, bridge failure, unsupported platforms, missing/corrupt assets,
invalid persisted state, and malformed problem data are visible states. Study
features remain usable when judging or animation is unavailable.
