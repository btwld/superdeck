import 'package:flutter/material.dart';

import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:genui/genui.dart';

import '../schemas/genui_action_schema.dart';
import 'user_action_dispatch.dart';
import '../../debug_logger.dart';
import '../../ui/ui.dart';

import 'ask_user_question_cards.dart';
import 'catalog_question_step.dart';
import 'component_schema.dart';
import 'typed_catalog_item.dart';
import 'wizard_option_icon.dart';

part 'ask_user_radio.g.dart';

// ─────────────────────────────────── SCHEMA ───────────────────────────────────

/// Schema for a radio option with title and optional description.
@AckType(name: 'InputOption')
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
final askUserRadio = typedCatalogItem<AskUserRadioType>(
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
  parse: AskUserRadioType.parse,
  widgetBuilder: (context, data) =>
      _AskUserRadioContent(data: data, itemContext: context),
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
    action: widget.data.action,
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

    if (options.isEmpty) {
      debugLog.log('AskUserRadio', 'WARNING: radio input has no options.');
      return const SdBody('No options available');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 620
            ? 3
            : constraints.maxWidth >= 420
            ? 2
            : 1;
        const spacing = 12.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (columnCount - 1)) / columnCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = _selectedIndex == index;

            return SizedBox(
              width: cardWidth,
              child: RadioOptionCard(
                title: option.title,
                description: option.description,
                icon: (option.icon ?? WizardOptionIcon.fallbackFor(index))
                    .iconData,
                selected: isSelected,
                onTap: () => setState(() => _selectedIndex = index),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
