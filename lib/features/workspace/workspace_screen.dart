import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

import '../../app/app_controller.dart';
import '../../core/design/olt_design.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _code = CodeLineEditingController.fromText(widget.controller.draft)
      ..addListener(_saveCode);
    _notes = TextEditingController(text: widget.controller.notes)
      ..addListener(_saveNotes);
  }

  void _saveCode() => widget.controller.updateDraft(_code.text);
  void _saveNotes() => widget.controller.updateNotes(_notes.text);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && !widget.controller.timerPaused) {
      widget.controller.toggleTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
              _StatusRail(controller: widget.controller),
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
        Container(
          padding: const EdgeInsets.all(OltSpace.x2),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: OltColors.border)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                const OltButton(
                  label: 'RUN TESTS',
                  signal: true,
                  onPressed: null,
                ),
                const SizedBox(width: OltSpace.x2),
                const OltButton(label: 'SUBMIT', onPressed: null),
                if (constraints.maxWidth > 500) ...[
                  const Spacer(),
                  Flexible(
                    child: Text(
                      'TEST/NOT-RUN · JUDGE/UNAVAILABLE',
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

  Widget _resultsPane() => const OltPanel(
    panelKey: Key('results-pane'),
    label: 'RESULTS/LOCAL · TEST/NOT-RUN',
    child: Center(child: Text('Run tests to inspect structured output.')),
  );

  Widget _animationPane() => OltPanel(
    panelKey: const Key('animation-pane'),
    label: 'ANIMATION/LOCAL',
    child: _animationContent(),
  );

  Widget _animationContent() => const Center(
    child: Padding(
      padding: EdgeInsets.all(OltSpace.x4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, size: 48, color: OltColors.muted),
          SizedBox(height: OltSpace.x2),
          Text('ANIM/LOCAL-ASSET-MISSING', style: microStyle),
          SizedBox(height: OltSpace.x2),
          Text(
            'LeetCodeAnimation media is not bundled because the source has no redistribution license.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
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
  const _StatusRail({required this.controller});

  final AppController controller;

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
          final compact = constraints.maxWidth < 600;
          return Row(
            children: [
              Text(
                compact ? 'OLT' : 'OFFLINE LEETCODE TRAINER',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(width: OltSpace.x4),
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
              OltButton(
                buttonKey: const Key('focus-toggle'),
                label: controller.state.focusMode ? 'EXIT FOCUS' : 'FOCUS',
                onPressed: controller.toggleFocus,
              ),
            ],
          );
        },
      ),
    );
  }
}
