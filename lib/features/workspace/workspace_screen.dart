import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

import '../../app/app_controller.dart';
import '../../core/design/olt_design.dart';
import '../judge/judge_models.dart';
import '../animations/animation_viewer.dart';
import '../problems/problem_browser.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen>
    with WidgetsBindingObserver {
  late final CodeLineEditingController _code;
  late final TextEditingController _notes;
  late String _loadedSlug;
  bool _pausedByLifecycle = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadedSlug = widget.controller.problem.slug;
    widget.controller.addListener(_syncProblem);
    _code = CodeLineEditingController.fromText(widget.controller.draft)
      ..addListener(_saveCode);
    _notes = TextEditingController(text: widget.controller.notes)
      ..addListener(_saveNotes);
  }

  void _saveCode() => widget.controller.updateDraft(_code.text);
  void _saveNotes() => widget.controller.updateNotes(_notes.text);

  void _syncProblem() {
    if (_loadedSlug == widget.controller.problem.slug) return;
    _loadedSlug = widget.controller.problem.slug;
    _code.text = widget.controller.draft;
    _notes.text = widget.controller.notes;
  }

  Future<void> _openBrowser() => showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      child: ProblemBrowser(
        problems: widget.controller.problems,
        progress: widget.controller.state.progress,
        onSelected: (problem) {
          widget.controller.selectProblem(problem);
          Navigator.pop(context);
        },
      ),
    ),
  );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_pausedByLifecycle) {
        _pausedByLifecycle = false;
        widget.controller.toggleTimer();
      }
    } else if (!widget.controller.timerPaused) {
      _pausedByLifecycle = true;
      widget.controller.toggleTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_syncProblem);
    _code
      ..removeListener(_saveCode)
      ..dispose();
    _notes
      ..removeListener(_saveNotes)
      ..dispose();
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final compact = MediaQuery.sizeOf(context).width < 900;
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _StatusRail(
                controller: widget.controller,
                onBrowse: _openBrowser,
              ),
              Expanded(
                child: compact
                    ? _compactBody(widget.controller.compactIndex)
                    : _desktopBody(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: compact
            ? NavigationBar(
                selectedIndex: widget.controller.compactIndex,
                onDestinationSelected: widget.controller.setCompactIndex,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.description_outlined),
                    label: 'PROBLEM',
                  ),
                  NavigationDestination(icon: Icon(Icons.code), label: 'CODE'),
                  NavigationDestination(
                    icon: Icon(Icons.fact_check_outlined),
                    label: 'RESULTS',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.animation),
                    label: 'ANIMATION',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.notes),
                    label: 'NOTES',
                  ),
                ],
              )
            : null,
      );
    },
  );

  Widget _desktopBody() {
    final focused = widget.controller.state.focusMode;
    return Padding(
      padding: const EdgeInsets.all(OltSpace.x2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 4, child: _problemPane()),
          const SizedBox(width: OltSpace.x2),
          Expanded(flex: 6, child: _editorPane()),
          if (!focused) ...[
            const SizedBox(width: OltSpace.x2),
            Expanded(flex: 3, child: _rightPane()),
          ],
        ],
      ),
    );
  }

  Widget _compactBody(int index) => Padding(
    padding: const EdgeInsets.all(OltSpace.x2),
    child: switch (index) {
      0 => _problemPane(),
      1 => _editorPane(),
      2 => _resultsPane(),
      3 => _animationPane(),
      _ => _notesPane(),
    },
  );

  Widget _problemPane() => OltPanel(
    panelKey: const Key('problem-pane'),
    label: 'PROBLEM/0001 · REF/BLIND75-TWO-SUM · EASY',
    child: SelectionArea(
      child: ListView(
        padding: const EdgeInsets.all(OltSpace.x4),
        children: [
          Row(
            children: [
              OltButton(
                label: 'PREV',
                onPressed: () => widget.controller.selectAdjacent(-1),
              ),
              const SizedBox(width: OltSpace.x2),
              OltButton(
                label: 'NEXT',
                onPressed: () => widget.controller.selectAdjacent(1),
              ),
            ],
          ),
          const SizedBox(height: OltSpace.x4),
          Text(
            widget.controller.problem.title.toUpperCase(),
            maxLines: 2,
            style: const TextStyle(
              fontSize: 64,
              height: .9,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: OltSpace.x4),
          Text(
            widget.controller.problem.description,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: OltSpace.x4),
          for (final example in widget.controller.problem.examples) ...[
            const Text('EXAMPLE', style: microStyle),
            const SizedBox(height: OltSpace.x1),
            Text('INPUT  ${example.input}'),
            Text('OUTPUT ${example.output}'),
            if (example.explanation != null) Text(example.explanation!),
            const SizedBox(height: OltSpace.x4),
          ],
          const Text('CONSTRAINTS', style: microStyle),
          const SizedBox(height: OltSpace.x1),
          for (final constraint in widget.controller.problem.constraints)
            Text('— $constraint'),
        ],
      ),
    ),
  );

  Widget _editorPane() => OltPanel(
    panelKey: const Key('editor-pane'),
    label: 'LANG/PYTHON · DRAFT/LOCAL · EDITOR/RE-EDITOR',
    child: Column(
      children: [
        Expanded(
          child: CodeEditor(
            controller: _code,
            style: const CodeEditorStyle(
              fontFamily: 'monospace',
              fontSize: 15,
              fontHeight: 1.45,
              textColor: OltColors.foreground,
              backgroundColor: OltColors.background,
              cursorColor: OltColors.signal,
              cursorLineColor: OltColors.raised,
            ),
            wordWrap: false,
            indicatorBuilder:
                (context, editingController, chunkController, notifier) =>
                    DefaultCodeLineNumber(
                      controller: editingController,
                      notifier: notifier,
                    ),
            leadingDivider: const SizedBox(
              width: 1,
              child: ColoredBox(color: OltColors.border),
            ),
          ),
        ),
        if (widget.controller.judgeResult != null)
          SizedBox(height: 144, child: _resultContent()),
        Container(
          padding: const EdgeInsets.all(OltSpace.x2),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: OltColors.border)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                OltButton(
                  label: 'RUN TESTS',
                  signal: true,
                  onPressed:
                      widget.controller.judgeAvailable &&
                          !widget.controller.judging
                      ? () => widget.controller.runTests(submit: false)
                      : null,
                ),
                const SizedBox(width: OltSpace.x2),
                OltButton(
                  label: 'SUBMIT',
                  onPressed:
                      widget.controller.judgeAvailable &&
                          !widget.controller.judging
                      ? () => widget.controller.runTests(submit: true)
                      : null,
                ),
                if (constraints.maxWidth > 500) ...[
                  const Spacer(),
                  Flexible(
                    child: Text(
                      widget.controller.judging
                          ? 'TEST/RUNNING · JUDGE/ACTIVE'
                          : widget.controller.judgeAvailable
                          ? 'TEST/READY · JUDGE/DESKTOP'
                          : 'TEST/NOT-RUN · JUDGE/UNAVAILABLE',
                      overflow: TextOverflow.ellipsis,
                      style: microStyle.copyWith(color: OltColors.foreground),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _rightPane() => OltPanel(
    panelKey: const Key('right-pane'),
    label: 'AUX/ANIMATION+NOTES · DATA/LOCAL',
    child: Column(
      children: [
        Expanded(child: _animationContent()),
        const Divider(height: 1, color: OltColors.border),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(OltSpace.x2),
            child: TextField(
              controller: _notes,
              expands: true,
              maxLines: null,
              minLines: null,
              decoration: const InputDecoration(
                labelText: 'NOTES/LOCAL',
                alignLabelWithHint: true,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _resultsPane() => OltPanel(
    panelKey: const Key('results-pane'),
    label: 'RESULTS/LOCAL · TEST/NOT-RUN',
    child: _resultContent(),
  );

  Widget _resultContent() {
    final result = widget.controller.judgeResult;
    if (widget.controller.judging) {
      return const Center(child: CircularProgressIndicator());
    }
    if (result == null) {
      return const Center(
        child: Text('Run tests to inspect structured output.'),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(OltSpace.x2),
      children: [
        Text(
          'TEST/${result.passedTests.toString().padLeft(2, '0')}-PASSED · '
          'TOTAL/${result.totalTests.toString().padLeft(2, '0')} · '
          'TIME/${result.executionTimeMs}MS',
          style: microStyle.copyWith(
            color: result.status == JudgeStatus.passed
                ? OltColors.signal
                : OltColors.danger,
          ),
        ),
        const SizedBox(height: OltSpace.x2),
        for (final test in result.testResults)
          Padding(
            padding: const EdgeInsets.only(bottom: OltSpace.x1),
            child: Text(
              '${test.passed ? 'PASS' : 'FAIL'} · ${test.id} · '
              '${test.error ?? test.output}',
            ),
          ),
        if (result.stderr.isNotEmpty)
          Text(result.stderr, style: const TextStyle(color: OltColors.danger)),
      ],
    );
  }

  Widget _animationPane() => OltPanel(
    panelKey: const Key('animation-pane'),
    label: 'ANIMATION/LOCAL',
    child: _animationContent(),
  );

  Widget _animationContent() => AnimationViewer(
    key: ValueKey(widget.controller.problem.slug),
    title: widget.controller.problem.title,
    assetPath: null,
  );

  Widget _notesPane() => OltPanel(
    panelKey: const Key('notes-pane'),
    label: 'NOTES/TWO-SUM · STORAGE/LOCAL',
    child: Padding(
      padding: const EdgeInsets.all(OltSpace.x2),
      child: TextField(
        controller: _notes,
        expands: true,
        maxLines: null,
        minLines: null,
        decoration: const InputDecoration(alignLabelWithHint: true),
      ),
    ),
  );
}

class _StatusRail extends StatelessWidget {
  const _StatusRail({required this.controller, required this.onBrowse});

  final AppController controller;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final elapsed = Duration(seconds: controller.elapsedSeconds);
    String two(int value) => value.toString().padLeft(2, '0');
    final time =
        '${two(elapsed.inHours)}:${two(elapsed.inMinutes % 60)}:${two(elapsed.inSeconds % 60)}';
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: OltSpace.x2),
      decoration: const BoxDecoration(
        color: OltColors.surface,
        border: Border(bottom: BorderSide(color: OltColors.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 840;
          return Row(
            children: [
              if (!compact) ...[
                const Text(
                  'OFFLINE LEETCODE TRAINER',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.5,
                  ),
                ),
                const SizedBox(width: OltSpace.x4),
              ],
              if (!compact)
                const Expanded(
                  child: Text(
                    'APP/OLT-001 · MODE/OFFLINE · DATA/LOCAL · LANG/PYTHON',
                    style: microStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Spacer(),
              Text('T-$time', style: microStyle),
              IconButton(
                tooltip: controller.timerPaused
                    ? 'Resume timer'
                    : 'Pause timer',
                onPressed: controller.toggleTimer,
                icon: Icon(
                  controller.timerPaused ? Icons.play_arrow : Icons.pause,
                  size: 18,
                ),
              ),
              if (!compact)
                OltButton(label: 'BROWSE/75', onPressed: onBrowse)
              else
                IconButton(
                  tooltip: 'Browse Blind 75',
                  onPressed: onBrowse,
                  icon: const Icon(Icons.list, size: 18),
                ),
              if (!compact)
                OltButton(
                  buttonKey: const Key('focus-toggle'),
                  label: controller.state.focusMode ? 'EXIT FOCUS' : 'FOCUS',
                  onPressed: controller.toggleFocus,
                )
              else
                IconButton(
                  key: const Key('focus-toggle'),
                  tooltip: controller.state.focusMode
                      ? 'Exit focus mode'
                      : 'Enter focus mode',
                  onPressed: controller.toggleFocus,
                  icon: const Icon(Icons.center_focus_strong, size: 18),
                ),
            ],
          );
        },
      ),
    );
  }
}
