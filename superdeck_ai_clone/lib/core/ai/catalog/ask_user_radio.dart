import 'package:flutter/material.dart';

import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:genui/genui.dart';
import 'package:remix/remix.dart';

import 'package:superdeck_ai/core/ai/schemas/genui_action_schema.dart';
import 'package:superdeck_ai/core/ai/catalog/user_action_dispatch.dart';
import 'package:superdeck_ai/core/debug_logger.dart';
import 'package:superdeck_ai/core/ui/ui.dart';

import 'ask_user_question_cards.dart';
import 'catalog_question_step.dart';

part 'ask_user_radio.g.dart';

// ─────────────────────────────────── SCHEMA ───────────────────────────────────

/// Schema for a radio option with title and optional description.
@AckType(name: 'InputOption')
final _inputOptionSchema = Ack.object({
  'title': Ack.string().describe('Option title displayed to user'),
  'description': Ack.string().optional().describe('Optional description text'),
}).describe('Option with title and optional description');

/// Schema for AskUserRadio component.
///
/// Displays a question with radio button options for single selection.
@AckType(name: 'AskUserRadio')
final _askUserRadioSchema = Ack.object({
  'question': Ack.string().describe('The question to display to the user'),
  'description': Ack.string().optional().describe(
    'Additional context or instructions',
  ),
  'options': Ack.list(
    _inputOptionSchema,
  ).describe('Radio options with title and description for single selection'),
  'action': actionSchema,
}).describe('A question with radio button options. User selects one option.');

// ─────────────────────────────────── CATALOG ITEM ───────────────────────────────────

/// AskUserRadio catalog component for single-selection questions.
final askUserRadio = CatalogItem(
  name: 'AskUserRadio',
  dataSchema: _askUserRadioSchema.toJsonSchemaBuilder(),
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "AskUserRadio": {
              "question": "Who is your target audience?",
              "description": "Select the group that best describes your viewers.",
              "options": [
                {"title": "Business Professionals", "description": "Corporate stakeholders"},
                {"title": "Students", "description": "Academic learners"},
                {"title": "General Public", "description": "Broad audience"}
              ],
              "action": {"name": "submit_answer", "context": []}
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = AskUserRadioType.parse(context.data);
    return _AskUserRadioContent(data: data, itemContext: context);
  },
);

// ─────────────────────────────────── WIDGET ───────────────────────────────────

class _AskUserRadioContent extends StatefulWidget {
  final AskUserRadioType data;
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
      'message': option.title,
    };
  }

  void _submitAction() => submitCatalogActionIfValid(
    canSubmit: _canSubmit,
    itemContext: widget.itemContext,
    rawAction: widget.data.action,
    contextBuilder: _buildActionContext,
  );

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

  Widget _buildOptions() {
    final options = widget.data.options;
    final optionsRow = FlexBoxStyler()
        .spacing(16)
        .wrap(WidgetModifierConfig.intrinsicHeight());

    if (options.isEmpty) {
      debugLog.log('AskUserRadio', 'WARNING: radio input has no options.');
      return const SdBody('No options available');
    }

    return optionsRow(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = _selectedIndex == index;

        return Expanded(
          child: RadioOptionCard(
            title: option.title,
            description: option.description,
            selected: isSelected,
            onTap: () {
              setState(() => _selectedIndex = index);
            },
          ),
        );
      }).toList(),
    );
  }
}
