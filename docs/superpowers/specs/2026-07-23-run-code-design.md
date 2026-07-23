# Run Code Design

## Goal

Add a separate **Run Code** action that executes the current editor contents as
freeform Python and displays stdout, syntax/runtime errors, status, and elapsed
time in the existing result console. Existing **Run Tests** and **Submit**
behavior must remain unchanged.

## Approaches Considered

1. **Add a scratch mode to the existing judge request (selected).** The desktop
   Docker runner and Android Python service branch only at the point where
   Python is invoked. This preserves validation, output limits, timeouts, and
   process isolation with the smallest cross-platform change.
2. Add a separate `/run` endpoint and Android method-channel method. This makes
   the HTTP surface explicit but duplicates transport, validation, timeout, and
   error handling.
3. Launch a local terminal process from Flutter. This would bypass Android,
   Docker limits, and the existing security boundary, so it is rejected.

## Data Model and Execution

Add a request mode with three explicit values: `scratch`, `tests`, and
`submit`. Serialize the mode through the existing desktop and Android payloads.
Keep the existing `submit` compatibility field only where the Cojudge bridge
still requires it.

For `scratch`, execute the source once in the same restricted Python namespace
used by the current judge, capture stdout/stderr, and do not load a `Solution`
class or run problem tests. Return the existing `JudgeResult` shape with zero
test counts. Syntax and runtime exceptions return `error`; successful execution
returns `passed`. Existing byte, output, time, memory, Docker, and Android
service limits remain in force.

No stdin value is added in this version. Because execution behavior is selected
by a request mode rather than a separate API, a future optional `stdin` payload
can be added without replacing the runner or UI flow.

## Controller and UI

Add `runCode()` beside `runTests()` in `AppController`. Scratch runs update the
shared `judgeResult` but do not write test history, review telemetry, solved
state, or submission state.

Add **RUN CODE** before **RUN TESTS** and **SUBMIT** in the editor action row.
The existing result panel remains the output surface. Its compact header shows
scratch status and elapsed time without test-count language.

Add **COPY OUTPUT** and **CLEAR** actions to the result header. Copy combines
non-empty stdout and stderr into one clipboard payload. Clear removes only the
current result; it does not alter the draft or persisted test history.

The controls reuse the current angular buttons, mono typography, hairline
borders, and signal colors. No terminal emulator, tabs, input box, dependency,
or new full-size panel is introduced.

## Error Handling

- Empty output still shows the final status and execution time.
- Syntax/runtime errors are shown in the existing error color.
- Copy is disabled when no stdout/stderr exists.
- All execution actions remain disabled while a judge request is active.
- Judge unavailability uses the existing unavailable result.

## Tests and Verification

- Model serialization/validation distinguishes all three modes.
- Desktop payload forwarding includes scratch mode.
- Android payload forwarding includes scratch mode.
- Python runner tests cover print output, syntax error, runtime error, and no
  `Solution` requirement.
- Controller tests prove scratch runs do not mutate test history or progress.
- Widget tests cover Run Code, scratch result metadata, Clear, and Copy Output.
- Existing Run Tests, Submit, judge, storage, animation, and review tests remain
  green.
- Run formatting, dependency resolution, analysis, the full Flutter test suite,
  Linux release build, and Android release build before committing.
