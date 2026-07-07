import 'package:flutter/material.dart';

import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:genui/genui.dart';
import 'package:remix/remix.dart';

import '../prompts/font_styles.dart';
import 'user_action_dispatch.dart';
import '../schemas/genui_action_schema.dart';
import '../schemas/wizard_context_keys.dart';
import '../../ui/ui.dart';

import 'ask_user_question_cards.dart';
import 'catalog_question_step.dart';
import 'component_schema.dart';
import 'typed_catalog_item.dart';

part 'ask_user_style.g.dart';

// ─────────────────────────────────── SCHEMA ───────────────────────────────────

/// Schema for a style option with colors and fonts.
@AckType(name: 'StyleOption')
final _styleOptionSchema = Ack.object({
  'id': Ack.string().describe('Unique identifier using snake_case'),
  'title': Ack.string().describe('Visual mood or theme name'),
  'description': Ack.string().describe('Brief explanation of the visual feel'),
  'colors': Ack.list(
    Ack.string().describe('Hex color value'),
  ).describe('List of hex color strings representing the color palette'),
  'headlineFont': Ack.enumValues<HeadlineFont>(
    HeadlineFont.values,
  ).describe(HeadlineFont.schemaDescription),
  'bodyFont': Ack.enumValues<BodyFont>(
    BodyFont.values,
  ).describe(BodyFont.schemaDescription),
}).describe('Style option with colors and fonts for visual theming');

/// Schema for AskUserStyle component.
///
/// Displays a question with visual style options for selection.
@AckType(name: 'AskUserStyle')
final _askUserStyleSchema =
    Ack.object({
      'question': Ack.string().describe('The question to display to the user'),
      'description': Ack.string().optional().describe(
        'Additional context or instructions',
      ),
      'styleOptions': Ack.list(
        _styleOptionSchema,
      ).describe('Style options with colors and fonts for visual theming'),
      'action': actionSchema,
    }).describe(
      'A question with visual style options. User selects one style with colors and fonts.',
    );

// ─────────────────────────────────── CATALOG ITEM ───────────────────────────────────

/// AskUserStyle catalog component for visual style selection.
final askUserStyle = typedCatalogItem<AskUserStyleType>(
  name: 'AskUserStyle',
  dataSchema: componentSchema(_askUserStyleSchema.toJsonSchemaBuilder()),
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "AskUserStyle",
          "question": "Choose a visual style",
          "description": "Pick the palette and fonts that best fit your presentation.",
          "styleOptions": [
            {
              "id": "professional_clean",
              "title": "Professional & Clean",
              "description": "Muted palette with crisp typography.",
              "colors": ["#F8FAFC", "#1E3A8A", "#475569"],
              "headlineFont": "montserrat",
              "bodyFont": "openSans"
            },
            {
              "id": "playful_bright",
              "title": "Playful & Bright",
              "description": "Cheerful colors with friendly fonts.",
              "colors": ["#F5F3FF", "#5B21B6", "#6B7280"],
              "headlineFont": "lobster",
              "bodyFont": "inter"
            }
          ],
          "action": {"name": "submit_answer", "context": []}
        }
      ]
    ''',
  ],
  parse: AskUserStyleType.parse,
  widgetBuilder: (context, data) =>
      _AskUserStyleContent(data: data, itemContext: context),
);

// ─────────────────────────────────── WIDGET ───────────────────────────────────

class _AskUserStyleContent extends StatefulWidget {
  final AskUserStyleType data;
  final CatalogItemContext itemContext;

  const _AskUserStyleContent({required this.data, required this.itemContext});

  @override
  State<_AskUserStyleContent> createState() => _AskUserStyleContentState();
}

class _AskUserStyleContentState extends State<_AskUserStyleContent> {
  int? _selectedStyleIndex;
  StyleOptionType? _selectedStyleOption;

  bool get _canSubmit => _selectedStyleOption != null;

  Map<String, dynamic> _buildActionContext() {
    if (_selectedStyleOption case final option?) {
      return {
        WizardContextKeys.style: option.title,
        WizardContextKeys.title: option.title,
        WizardContextKeys.description: option.description,
        WizardContextKeys.colors: option.colors.toList(),
        WizardContextKeys.headlineFont: option.headlineFont.name,
        WizardContextKeys.bodyFont: option.bodyFont.name,
        WizardContextKeys.message: option.title,
      };
    }
    return {};
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
    final options = widget.data.styleOptions;

    if (options.isEmpty) {
      return const SdBody('No style options configured');
    }

    final optionsRow = FlexBoxStyler()
        .spacing(16)
        .wrap(WidgetModifierConfig.intrinsicHeight());

    return optionsRow(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = _selectedStyleIndex == index;

        return Expanded(
          child: StyleOptionCard(
            title: option.title,
            description: option.description,
            colors: option.colors.toList(),
            headlineFontId: option.headlineFont.name,
            bodyFontId: option.bodyFont.name,
            selected: isSelected,
            onTap: () {
              setState(() {
                _selectedStyleIndex = index;
                _selectedStyleOption = option;
              });
            },
          ),
        );
      }).toList(),
    );
  }
}
