import 'package:flutter/material.dart';

import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:genui/genui.dart';
import 'package:remix/remix.dart';

import '../schemas/genui_action_schema.dart';
import 'user_action_dispatch.dart';

import 'ask_user_question_cards.dart';
import 'catalog_question_step.dart';
import 'component_schema.dart';
import 'typed_catalog_item.dart';

part 'ask_user_checkbox.ack.dart';
part 'ask_user_checkbox.ack.g.dart';

// ─────────────────────────────────── SCHEMA ───────────────────────────────────

const _defaultMinSelections = 1;

/// Schema for AskUserCheckbox component.
///
/// Displays a question with checkbox items for multiple selection.
@AckInfer(name: 'AskUserCheckbox')
final _askUserCheckboxSchema =
    Ack.object({
          'question': Ack.string().describe(
            'The question to display to the user',
          ),
          'description': Ack.string().optional().describe(
            'Additional context or instructions',
          ),
          'items': Ack.list(Ack.string().minLength(1))
              .nonEmpty()
              .unique()
              .describe(
                'Unique, non-empty checkbox items for multiple selection',
              ),
          'selectedItems': Ack.list(
            Ack.string(),
          ).unique().optional().describe('Initially selected items'),
          'minSelections': Ack.integer()
              .min(0)
              .optional()
              .describe('Minimum selections required, default 1'),
          'maxSelections': Ack.integer()
              .min(0)
              .optional()
              .describe('Maximum selections allowed'),
          'action': actionSchema,
        })
        .withConstraint(const _CheckboxSelectionConstraint())
        .describe(
          'A question with checkbox items. User selects one or more items.',
        );

final class _CheckboxSelectionConstraint
    extends Constraint<Map<String, Object?>>
    with Validator<Map<String, Object?>> {
  const _CheckboxSelectionConstraint()
    : super(
        constraintKey: 'checkbox_selection_relationships',
        description: 'Checkbox selections and bounds must match the items.',
      );

  @override
  bool isValid(Map<String, Object?> value) {
    final items = value['items']! as List<Object?>;
    final selectedItems = value['selectedItems'] as List<Object?>?;
    final minSelections =
        value['minSelections'] as int? ?? _defaultMinSelections;
    final maxSelections = value['maxSelections'] as int? ?? items.length;

    if (maxSelections > items.length || minSelections > maxSelections) {
      return false;
    }

    return selectedItems == null ||
        (selectedItems.length <= maxSelections &&
            selectedItems.every(items.contains));
  }

  @override
  String buildMessage(Map<String, Object?> value) {
    return 'Selections must belong to items; bounds must fit the item count, '
        'minimum must not exceed maximum, and the initial selection must not '
        'exceed the maximum.';
  }
}

// ─────────────────────────────────── CATALOG ITEM ───────────────────────────────────

/// AskUserCheckbox catalog component for multiple-selection questions.
final askUserCheckbox = typedCatalogItem<AskUserCheckbox>(
  name: 'AskUserCheckbox',
  dataSchema: componentSchema(_askUserCheckboxSchema.toJsonSchemaBuilder()),
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "AskUserCheckbox",
          "question": "What topics should we cover?",
          "description": "Select all that apply.",
          "items": ["History", "Current State", "Future Trends", "Case Studies"],
          "minSelections": 1,
          "maxSelections": 3,
          "action": {"name": "submit_answer", "context": []}
        }
      ]
    ''',
  ],
  parse: AskUserCheckbox.parse,
  widgetBuilder: (context, data) =>
      _AskUserCheckboxContent(data: data, itemContext: context),
);

// ─────────────────────────────────── WIDGET ───────────────────────────────────

class _AskUserCheckboxContent extends StatefulWidget {
  final AskUserCheckbox data;
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
    final minSelections = widget.data.minSelections ?? _defaultMinSelections;
    final maxSelections = widget.data.maxSelections;
    final count = _selectedChoices.length;
    if (count < minSelections) return false;
    if (maxSelections != null && count > maxSelections) return false;
    return true;
  }

  Map<String, dynamic> _buildActionContext() {
    return {'selectedOptions': _selectedChoices.toList()};
  }

  void _submitAction() => submitCatalogActionIfValid(
    canSubmit: _canSubmit,
    itemContext: widget.itemContext,
    action: widget.data.action,
    contextBuilder: _buildActionContext,
  );

  Widget _buildItems() {
    final items = widget.data.items;
    final column = FlexBoxStyler().column().spacing(8);

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
}
