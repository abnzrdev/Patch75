import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

import '../../app/app_controller.dart';
import '../../core/design/olt_design.dart';
import '../judge/judge_models.dart';
import '../materials/learning_materials_panel.dart';
import '../problems/problem.dart';
import '../problems/problem_browser.dart';
import 'python_code_theme.dart';

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
                    icon: Icon(Icons.attach_file),
                    label: 'MATERIALS',
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
    label:
        'PROBLEM/${widget.controller.problem.id.toString().padLeft(4, '0')} · '
        'REF/${widget.controller.problem.slug.toUpperCase()} · '
        '${widget.controller.problem.difficulty.toUpperCase()}',
    child: SelectionArea(
      child: ListView(
        key: const Key('problem-scroll'),
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
            key: const Key('problem-title'),
            widget.controller.problem.title.toUpperCase(),
            style: const TextStyle(
              color: OltColors.foreground,
              fontSize: 44,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: OltSpace.x3),
          Wrap(
            spacing: OltSpace.x2,
            runSpacing: OltSpace.x1,
            children: [
              for (final topic in widget.controller.problem.topics)
                _Tag(topic.toUpperCase()),
            ],
          ),
          const SizedBox(height: OltSpace.x6),
          const Text('DESCRIPTION', style: microStyle),
          const SizedBox(height: OltSpace.x2),
          _InlineCodeText(
            key: const Key('problem-description'),
            text: widget.controller.problem.description,
          ),
          const SizedBox(height: OltSpace.x6),
          for (final (index, example)
              in widget.controller.problem.examples.indexed) ...[
            _ExampleCard(index: index + 1, example: example),
            const SizedBox(height: OltSpace.x4),
          ],
          const Text('CONSTRAINTS', style: microStyle),
          const SizedBox(height: OltSpace.x2),
          Container(
            key: const Key('constraint-list'),
            padding: const EdgeInsets.all(OltSpace.x3),
            decoration: const BoxDecoration(
              color: OltColors.raised,
              border: Border.fromBorderSide(
                BorderSide(color: OltColors.border),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final constraint in widget.controller.problem.constraints)
                  Padding(
                    padding: const EdgeInsets.only(bottom: OltSpace.x2),
                    child: _InlineCodeText(
                      text: '• $constraint',
                      compact: true,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: OltSpace.x4),
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
            key: const Key('code-editor'),
            controller: _code,
            padding: const EdgeInsets.all(OltSpace.x3),
            style: CodeEditorStyle(
              fontFamily: 'monospace',
              fontSize: 15,
              fontHeight: 1.45,
              textColor: OltColors.foreground,
              backgroundColor: OltColors.background,
              cursorColor: OltColors.signal,
              cursorLineColor: OltColors.raised,
              codeTheme: pythonCodeTheme,
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
            child: _notesContent(),
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
          Container(
            margin: const EdgeInsets.only(bottom: OltSpace.x2),
            padding: const EdgeInsets.all(OltSpace.x2),
            decoration: const BoxDecoration(
              color: OltColors.raised,
              border: Border.fromBorderSide(
                BorderSide(color: OltColors.border),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test.passed ? 'PASS' : 'FAIL',
                  style: microStyle.copyWith(
                    color: test.passed ? OltColors.signal : OltColors.danger,
                  ),
                ),
                const SizedBox(width: OltSpace.x2),
                Expanded(
                  child: Text(
                    '${test.id}\n${test.error ?? test.output}',
                    style: const TextStyle(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        if (result.stderr.isNotEmpty)
          Text(result.stderr, style: const TextStyle(color: OltColors.danger)),
      ],
    );
  }

  Widget _animationPane() => OltPanel(
    panelKey: const Key('animation-pane'),
    label: 'MATERIALS/LOCAL · STORAGE/PRIVATE',
    child: _animationContent(),
  );

  Widget _animationContent() => LearningMaterialsPanel(
    key: ValueKey(widget.controller.problem.slug),
    title: widget.controller.problem.title,
    materials: widget.controller.materials,
    busy: widget.controller.importingMaterial,
    errorMessage:
        widget.controller.materialError ?? widget.controller.animationError,
    onImportAnimation: widget.controller.importAnimation,
    onAddMaterial: widget.controller.addMaterial,
    onReplace: widget.controller.replaceMaterial,
    onRemove: widget.controller.removeMaterial,
    onExternalOpen: widget.controller.openMaterial,
  );

  Widget _notesPane() => OltPanel(
    panelKey: const Key('notes-pane'),
    label:
        'NOTES/${widget.controller.problem.slug.toUpperCase()} · STORAGE/LOCAL',
    child: Padding(
      padding: const EdgeInsets.all(OltSpace.x2),
      child: _notesContent(),
    ),
  );

  Widget _notesContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: TextField(
          key: const Key('notes-field'),
          controller: _notes,
          expands: true,
          maxLines: null,
          minLines: null,
          textAlignVertical: TextAlignVertical.top,
          scrollPadding: const EdgeInsets.all(OltSpace.x3),
          decoration: const InputDecoration(
            hintText: 'Capture the idea, invariant, or mistake to revisit…',
            alignLabelWithHint: true,
            contentPadding: EdgeInsets.all(OltSpace.x3),
          ),
        ),
      ),
      const SizedBox(height: OltSpace.x1),
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: _notes,
        builder: (_, value, _) => Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${value.text.characters.length} CHARACTERS',
            key: const Key('notes-count'),
            style: microStyle,
          ),
        ),
      ),
    ],
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: OltSpace.x2,
      vertical: OltSpace.x1,
    ),
    decoration: const BoxDecoration(
      color: OltColors.raised,
      border: Border.fromBorderSide(BorderSide(color: OltColors.border)),
    ),
    child: Text(label, style: microStyle),
  );
}

class _InlineCodeText extends StatelessWidget {
  const _InlineCodeText({required this.text, this.compact = false, super.key});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'`([^`]+)`');
    var offset = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > offset) {
        spans.add(TextSpan(text: text.substring(offset, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(
            color: OltColors.signal,
            backgroundColor: OltColors.raised,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      offset = match.end;
    }
    if (offset < text.length) spans.add(TextSpan(text: text.substring(offset)));
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: OltColors.readable,
          fontFamily: 'monospace',
          fontSize: compact ? 13 : 15,
          height: compact ? 1.45 : 1.65,
        ),
        children: spans,
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({required this.index, required this.example});

  final int index;
  final ProblemExample example;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('example-$index'),
    padding: const EdgeInsets.all(OltSpace.x3),
    decoration: const BoxDecoration(
      color: OltColors.raised,
      border: Border(
        left: BorderSide(color: OltColors.signal, width: 2),
        top: BorderSide(color: OltColors.border),
        right: BorderSide(color: OltColors.border),
        bottom: BorderSide(color: OltColors.border),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('EXAMPLE ${index.toString().padLeft(2, '0')}', style: microStyle),
        const SizedBox(height: OltSpace.x2),
        const Text('INPUT', style: microStyle),
        _InlineCodeText(text: example.input, compact: true),
        const SizedBox(height: OltSpace.x2),
        const Text('OUTPUT', style: microStyle),
        _InlineCodeText(text: example.output, compact: true),
        if (example.explanation != null) ...[
          const SizedBox(height: OltSpace.x2),
          Text(
            example.explanation!,
            style: const TextStyle(color: OltColors.readable),
          ),
        ],
      ],
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
