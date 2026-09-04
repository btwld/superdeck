import 'package:flutter/material.dart';

import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:genui/genui.dart';

import '../schemas/genui_action_schema.dart';
import 'user_action_dispatch.dart';

import 'ask_user_question_cards.dart';
import 'catalog_question_step.dart';
import 'component_schema.dart';
import 'typed_catalog_item.dart';
import 'wizard_option_icon.dart';

part 'ask_user_radio.ack.dart';
part 'ask_user_radio.ack.g.dart';

// ─────────────────────────────────── SCHEMA ───────────────────────────────────

/// Schema for a radio option with title and optional description.
@AckInfer(name: 'InputOption')
final _inputOptionSchema = Ack.object({
  'title': Ack.string().describe('Option title displayed to user'),
  'description': Ack.string().optional().describe('Optional description text'),
  'icon': Ack.enumValues<WizardOptionIcon>(
    WizardOptionIcon.values,
  ).optional().describe('Semantic icon for this option card'),
}).describe('Option with title and optional description');

/// Schema for AskUserRadio component.
///
/// Displays a question with radio button options for single selection.
@AckInfer(name: 'AskUserRadio')
final _askUserRadioSchema = Ack.object({
  'question': Ack.string().describe('The question to display to the user'),
  'description': Ack.string().optional().describe(
    'Additional context or instructions',
  ),
  'options': Ack.list(_inputOptionSchema).nonEmpty().describe(
    'Radio options with title and description for single selection',
  ),
  'action': actionSchema,
}).describe('A question with radio button options. User selects one option.');

// ─────────────────────────────────── CATALOG ITEM ───────────────────────────────────

/// AskUserRadio catalog component for single-selection questions.
final askUserRadio = typedCatalogItem<AskUserRadio>(
  name: 'AskUserRadio',
  dataSchema: componentSchema(_askUserRadioSchema.toJsonSchemaBuilder()),
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "AskUserRadio",
          "question": "Who is your target audience?",
          "description": "Select the group that best describes your viewers.",
          "options": [
            {"title": "Business Professionals", "description": "Corporate stakeholders", "icon": "business"},
            {"title": "Students", "description": "Academic learners", "icon": "education"},
            {"title": "General Public", "description": "Broad audience", "icon": "global"}
          ],
          "action": {"name": "submit_answer", "context": []}
        }
      ]
    ''',
  ],
  parse: AskUserRadio.parse,
  widgetBuilder: (context, data) =>
      _AskUserRadioContent(data: data, itemContext: context),
);

// ─────────────────────────────────── WIDGET ───────────────────────────────────

class _AskUserRadioContent extends StatefulWidget {
  final AskUserRadio data;
  final CatalogItemContext itemContext;

  const _AskUserRadioContent({required this.data, required this.itemContext});

  @override
  State<_AskUserRadioContent> createState() => _AskUserRadioContentState();
}

class _AskUserRadioContentState extends State<_AskUserRadioContent> {
  int? _selectedIndex;

  bool get _canSubmit => _selectedIndex != null;

  Map<String, dynamic> _buildActionContext() {
    if (_selectedIndex == null) return {};
    final option = widget.data.options[_selectedIndex!];

    return {
      'selectedOption': option.title,
      'selectedDescription': option.description,
    };
  }

  void _submitAction() => submitCatalogActionIfValid(
    canSubmit: _canSubmit,
    itemContext: widget.itemContext,
    action: widget.data.action,
    contextBuilder: _buildActionContext,
  );

  Widget _buildOptions() {
    final options = widget.data.options;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 620
            ? 3
            : constraints.maxWidth >= 420
            ? 2
            : 1;
        const spacing = 12.0;

        return Column(
          spacing: spacing,
          children: [
            for (
              var rowStart = 0;
              rowStart < options.length;
              rowStart += columnCount
            )
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: .stretch,
                  children: [
                    for (var column = 0; column < columnCount; column++) ...[
                      if (column > 0) const SizedBox(width: spacing),
                      Expanded(
                        child: switch (rowStart + column) {
                          final index when index < options.length =>
                            RadioOptionCard(
                              title: options[index].title,
                              description: options[index].description,
                              icon:
                                  (options[index].icon ??
                                          WizardOptionIcon.fallbackFor(index))
                                      .iconData,
                              selected: _selectedIndex == index,
                              onTap: () =>
                                  setState(() => _selectedIndex = index),
                            ),
                          _ => const SizedBox.shrink(),
                        },
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  void didUpdateWidget(covariant _AskUserRadioContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.question != widget.data.question) {
      _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CatalogQuestionStep(
      question: widget.data.question,
      description: widget.data.description,
      body: _buildOptions(),
      canSubmit: _canSubmit,
      onSubmit: _submitAction,
    );
  }
}
