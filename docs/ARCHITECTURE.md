# Architecture

Patch75 is a local-first Flutter application. `lib/main.dart` composes bundled
problem data, the JSON state store, local material storage, review scheduling,
and the platform-specific judge behind `AppController`.

## Source layout

```text
lib/
  app/            application controller
  core/           design primitives and local state storage
  features/
    problems/     bundled records, repository, and browser
    workspace/    responsive problem/editor/results/materials/notes UI
    judge/        validated requests and platform execution services
    materials/    private per-problem files
    learning/     hints and complexity checks
    custom_tests/ local user-authored inputs
    review/       FSRS records, attempts, queue, and summaries
    portability/  validated ZIP export/import
```

Runtime state is one versioned JSON document in the application-support
directory. `StateStore` serializes writes through a temporary sibling and
rename. `AppController` queues snapshots, exposes an awaitable flush, and keeps
save failures visible to the workspace.

## Judge flow

```text
Workspace → JudgeService
  Linux   → DesktopDockerJudgeService → 127.0.0.1 bridge → locked-down Docker
  Android → AndroidPythonJudgeService → MethodChannel → separate service process
  Web     → UnsupportedJudgeService
```

Linux currently accepts scratch Run Code only. Structured Tests/Submit are
rejected in Flutter and again at the bridge because the former cojudge backend
did not satisfy the required container boundary.

Android uses embedded CPython for offline convenience. The service is
non-exported, separate-process, payload-bounded, and killed after timeout; it is
not a hostile-code sandbox.

At widths below 900 logical pixels the workspace has five destinations:
Problem, Code, Results, Materials, and Notes. Wider layouts show problem,
editor, and a combined materials/notes pane.
