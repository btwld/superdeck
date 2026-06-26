import 'package:flutter/material.dart';

import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:genui/genui.dart';
import 'package:remix/remix.dart';

import '../schemas/genui_action_schema.dart';
import 'user_action_dispatch.dart';
import '../../debug_logger.dart';
import '../../ui/ui.dart';

import 'ask_user_question_cards.dart';
import 'catalog_question_step.dart';

part 'ask_user_checkbox.g.dart';

// ─────────────────────────────────── SCHEMA ───────────────────────────────────

/// Schema for AskUserCheckbox component.
///
/// Displays a question with checkbox items for multiple selection.
@AckType(name: 'AskUserCheckbox')
final _askUserCheckboxSchema = Ack.object({
  'question': Ack.string().describe('The question to display to the user'),
  'description': Ack.string().optional().describe(
    'Additional context or instructions',
  ),
  'items': Ack.list(
    Ack.string(),
  ).describe('Checkbox items as strings for multiple selection'),
  'selectedItems': Ack.list(
    Ack.string(),
  ).optional().describe('Initially selected items'),
  'minSelections': Ack.integer().optional().describe(
    'Minimum selections required, default 1',
  ),
  'maxSelections': Ack.integer().optional().describe(
    'Maximum selections allowed',
  ),
  'action': actionSchema,
}).describe('A question with checkbox items. User selects one or more items.');

// ─────────────────────────────────── CATALOG ITEM ───────────────────────────────────

/// AskUserCheckbox catalog component for multiple-selection questions.
final askUserCheckbox = CatalogItem(
  name: 'AskUserCheckbox',
  dataSchema: _askUserCheckboxSchema.toJsonSchemaBuilder(),
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "AskUserCheckbox": {
              "question": "What topics should we cover?",
              "description": "Select all that apply.",
              "items": ["History", "Current State", "Future Trends", "Case Studies"],
              "minSelections": 1,
              "maxSelections": 3,
              "action": {"name": "submit_answer", "context": []}
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = AskUserCheckboxType.parse(context.data);
    return _AskUserCheckboxContent(data: data, itemContext: context);
  },
);

// ─────────────────────────────────── WIDGET ───────────────────────────────────

class _AskUserCheckboxContent extends StatefulWidget {
  final AskUserCheckboxType data;
  final CatalogItemContext itemContext;

  const _AskUserCheckboxContent({
    required this.data,
    required this.itemContext,
  });

  @override
  State<_AskUserCheckboxContent> createState() =>
      _AskUserCheckboxContentState();
}

class _AskUserCheckboxContentState extends State<_AskUserCheckboxContent> {
  Set<String> _selectedChoices = {};

  @override
  void initState() {
    super.initState();
    _selectedChoices = widget.data.selectedItems?.toSet() ?? {};
  }

  bool get _canSubmit {
    final minSelections = widget.data.minSelections ?? 1;
    final maxSelections = widget.data.maxSelections;
    final count = _selectedChoices.length;
    if (count < minSelections) return false;
    if (maxSelections != null && count > maxSelections) return false;
    return true;
  }

  Map<String, dynamic> _buildActionContext() {
    return {
      'selectedOptions': _selectedChoices.toList(),
      'message': _selectedChoices.join(', '),
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
      body: _buildItems(),
      canSubmit: _canSubmit,
      onSubmit: _submitAction,
    );
  }

  Widget _buildItems() {
    final items = widget.data.items;
    final column = FlexBoxStyler().column().spacing(8);

    if (items.isEmpty) {
      debugLog.log('AskUserCheckbox', 'WARNING: checkbox input has no items.');
      return const SdBody('No options available');
    }

    return column(
      children: items.map((choice) {
        final isSelected = _selectedChoices.contains(choice);
        return CheckboxOptionCard(
          label: choice,
          selected: isSelected,
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedChoices = {..._selectedChoices}..remove(choice);
              } else {
                _selectedChoices = {..._selectedChoices}..add(choice);
              }
            });
          },
        );
      }).toList(),
    );
  }
}
