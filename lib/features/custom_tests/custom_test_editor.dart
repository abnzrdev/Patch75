import 'dart:convert';

import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../core/design/olt_design.dart';
import 'custom_test_case.dart';

class CustomTestEditor extends StatelessWidget {
  const CustomTestEditor({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(OltSpace.x2),
        child: Wrap(
          spacing: OltSpace.x2,
          runSpacing: OltSpace.x2,
          children: [
            OltButton(
              label: 'CREATE CUSTOM TEST',
              signal: true,
              onPressed: () => _edit(context),
            ),
            OltButton(
              label: 'RUN ALL ENABLED',
              onPressed: controller.customTests.any((item) => item.enabled)
                  ? controller.runCustomTests
                  : null,
            ),
          ],
        ),
      ),
      Expanded(
        child: ReorderableListView.builder(
          padding: const EdgeInsets.all(OltSpace.x2),
          itemCount: controller.customTests.length,
          onReorderItem: controller.reorderCustomTests,
          itemBuilder: (context, index) {
            final item = controller.customTests[index];
            return Container(
              key: ValueKey(item.id),
              margin: const EdgeInsets.only(bottom: OltSpace.x2),
              padding: const EdgeInsets.all(OltSpace.x2),
              decoration: const BoxDecoration(
                color: OltColors.raised,
                border: Border.fromBorderSide(
                  BorderSide(color: OltColors.border),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name),
                    subtitle: Text(jsonEncode(item.input)),
                    value: item.enabled,
                    onChanged: (value) =>
                        controller.toggleCustomTest(item.id, value),
                  ),
                  Wrap(
                    spacing: OltSpace.x1,
                    runSpacing: OltSpace.x1,
                    children: [
                      OltButton(
                        label: 'RUN',
                        onPressed: () =>
                            controller.runCustomTests(selected: item),
                      ),
                      OltButton(
                        label: 'EDIT',
                        onPressed: () => _edit(context, item),
                      ),
                      OltButton(
                        label: 'DUPLICATE',
                        onPressed: () =>
                            controller.duplicateCustomTest(item.id),
                      ),
                      OltButton(
                        label: 'DELETE',
                        onPressed: () => controller.deleteCustomTest(item.id),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      if (controller.customJudgeResult != null)
        Container(
          padding: const EdgeInsets.all(OltSpace.x2),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: OltColors.border)),
          ),
          child: Text(
            'CUSTOM RESULTS · ${controller.customJudgeResult!.passedTests}/'
            '${controller.customJudgeResult!.totalTests} PASSED\n'
            '${controller.customJudgeResult!.stderr}',
          ),
        ),
    ],
  );

  Future<void> _edit(BuildContext context, [CustomTestCase? existing]) =>
      showDialog<void>(
        context: context,
        builder: (_) =>
            _CustomTestDialog(controller: controller, existing: existing),
      );
}

class _CustomTestDialog extends StatefulWidget {
  const _CustomTestDialog({required this.controller, this.existing});

  final AppController controller;
  final CustomTestCase? existing;

  @override
  State<_CustomTestDialog> createState() => _CustomTestDialogState();
}

class _CustomTestDialogState extends State<_CustomTestDialog> {
  late final name = TextEditingController(text: widget.existing?.name ?? '');
  late final advanced = TextEditingController(
    text: const JsonEncoder.withIndent(
      '  ',
    ).convert(widget.existing?.input ?? {}),
  );
  late final fields = {
    for (final entry in widget.controller.problem.inputFieldTypes.entries)
      entry.key: TextEditingController(
        text: widget.existing?.input[entry.key] == null
            ? ''
            : jsonEncode(widget.existing!.input[entry.key]),
      ),
  };
  bool advancedMode = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    advanced.dispose();
    for (final controller in fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.existing == null ? 'CREATE CUSTOM TEST' : 'EDIT CUSTOM TEST',
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('custom-test-name'),
            controller: name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          SwitchListTile(
            title: const Text('Advanced JSON input'),
            value: advancedMode,
            onChanged: (value) => setState(() => advancedMode = value),
          ),
          if (advancedMode)
            TextField(
              key: const Key('custom-test-json'),
              controller: advanced,
              minLines: 5,
              maxLines: 12,
              decoration: const InputDecoration(labelText: 'JSON object'),
            )
          else
            for (final entry in fields.entries)
              TextField(
                key: ValueKey('custom-field-${entry.key}'),
                controller: entry.value,
                decoration: InputDecoration(
                  labelText:
                      '${entry.key} (${widget.controller.problem.inputFieldTypes[entry.key]})',
                ),
              ),
          if (error != null)
            Text(error!, style: const TextStyle(color: OltColors.danger)),
        ],
      ),
    ),
    actions: [
      OltButton(label: 'CANCEL', onPressed: () => Navigator.pop(context)),
      OltButton(label: 'SAVE', signal: true, onPressed: _save),
    ],
  );

  void _save() {
    try {
      final input = advancedMode
          ? jsonDecode(advanced.text)
          : {
              for (final entry in fields.entries)
                entry.key: jsonDecode(entry.value.text),
            };
      if (input is! Map) {
        throw const FormatException('Input must be an object.');
      }
      widget.controller.saveCustomTest(
        id: widget.existing?.id,
        name: name.text,
        input: Map<String, Object?>.from(input),
      );
      Navigator.pop(context);
    } on Object catch (value) {
      setState(() => error = 'Invalid custom test: $value');
    }
  }
}
