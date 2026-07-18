import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:genui/genui.dart';

import '../../../../../../core/domain/design/presentation_theme_catalog.dart';
import '../schemas/genui_action_schema.dart';
import '../schemas/wizard_context_keys.dart';
import '../../ui/ui.dart';

import 'ask_user_question_cards.dart';
import 'catalog_question_step.dart';
import 'component_schema.dart';
import 'presentation_theme_component_schema.dart';
import 'typed_catalog_item.dart';
import 'user_action_dispatch.dart';

part 'ask_user_style.g.dart';

// ─────────────────────────────────── SCHEMA ───────────────────────────────────

/// Schema for AskUserStyle component.
///
/// Displays exact catalog-backed presentation themes for selection.
@AckType(name: 'AskUserStyle')
final _askUserStyleSchema = Ack.object({
  'question': Ack.string().describe('The question to display to the user'),
  'description': Ack.string().optional().describe(
    'Additional context or instructions',
  ),
  'themeIds': Ack.list(Ack.string())
      .minItems(3)
      .maxItems(3)
      .describe('Exactly three registered theme IDs to offer in catalog order'),
  'action': actionSchema,
}).describe('A question with exact catalog-backed presentation theme options.');

// ─────────────────────────────────── CATALOG ITEM ───────────────────────────────────

/// AskUserStyle catalog component for visual style selection.
CatalogItem askUserStyleFor(PresentationThemeCatalog themeCatalog) {
  final exampleThemeIds = themeCatalog.currentThemes
      .take(3)
      .map((theme) => theme.id)
      .toList(growable: false);

  return typedCatalogItem<AskUserStyleType>(
    name: 'AskUserStyle',
    dataSchema: componentSchema(
      schemaWithPresentationThemeIds(
        _askUserStyleSchema.toJsonSchemaBuilder(),
        themeCatalog,
        paths: const [
          ['properties', 'themeIds', 'items'],
        ],
      ),
    ),
    exampleData: [
      () => const JsonEncoder.withIndent('  ').convert([
        {
          'id': 'root',
          'component': 'AskUserStyle',
          'question': 'Choose a visual style',
          'description':
              'Pick the design system that best fits your presentation.',
          'themeIds': exampleThemeIds,
          'action': {'name': 'submit_answer', 'context': <Object?>[]},
        },
      ]),
    ],
    parse: (data) => parseAskUserStyle(data, themeCatalog: themeCatalog),
    widgetBuilder: (context, data) => _AskUserStyleContent(
      data: data,
      itemContext: context,
      themeCatalog: themeCatalog,
    ),
  );
}

AskUserStyleType parseAskUserStyle(
  Object? data, {
  required PresentationThemeCatalog themeCatalog,
}) {
  final parsed = AskUserStyleType.parse(data);
  final unknownIds = parsed.themeIds
      .where((themeId) => themeCatalog.current(themeId) == null)
      .toList(growable: false);
  if (unknownIds.isNotEmpty) {
    throw FormatException(
      'Unknown presentation theme IDs: ${unknownIds.join(", ")}.',
    );
  }

  return parsed;
}

// ─────────────────────────────────── WIDGET ───────────────────────────────────

class _AskUserStyleContent extends StatefulWidget {
  const _AskUserStyleContent({
    required this.data,
    required this.itemContext,
    required this.themeCatalog,
  });

  final AskUserStyleType data;
  final CatalogItemContext itemContext;
  final PresentationThemeCatalog themeCatalog;

  @override
  State<_AskUserStyleContent> createState() => _AskUserStyleContentState();
}

class _AskUserStyleContentState extends State<_AskUserStyleContent> {
  int? _selectedStyleIndex;
  PresentationThemeDescriptor? _selectedTheme;

  bool get _canSubmit => _selectedTheme != null;

  Map<String, dynamic> _buildActionContext() {
    if (_selectedTheme case final theme?) {
      return buildThemeSelectionContext(
        theme.id,
        themeCatalog: widget.themeCatalog,
      );
    }
    return {};
  }

  void _submitAction() => submitCatalogActionIfValid(
    canSubmit: _canSubmit,
    itemContext: widget.itemContext,
    action: widget.data.action,
    contextBuilder: _buildActionContext,
  );

  Widget _buildOptions() {
    final options = widget.data.themeIds
        .map(widget.themeCatalog.current)
        .whereType<PresentationThemeDescriptor>()
        .toList(growable: false);

    if (options.isEmpty) {
      return const SdBody('No presentation themes configured');
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: .stretch,
        spacing: 16,
        children: [
          for (final (index, theme) in options.indexed)
            Expanded(
              child: StyleOptionCard(
                theme: theme,
                selected: _selectedStyleIndex == index,
                onTap: () {
                  setState(() {
                    _selectedStyleIndex = index;
                    _selectedTheme = theme;
                  });
                },
              ),
            ),
        ],
      ),
    );
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

/// Maps an exact catalog theme selection into Wizard context without turning
/// renderer-owned palette or font tokens into user overrides.
Map<String, dynamic> buildThemeSelectionContext(
  String themeId, {
  PresentationThemeCatalog? themeCatalog,
}) {
  final theme = (themeCatalog ?? PresentationThemeCatalog.withDefaults())
      .current(themeId);
  if (theme == null) {
    throw ArgumentError('Unknown presentation theme "$themeId".');
  }

  return {
    WizardContextKeys.themeId: theme.id,
    WizardContextKeys.title: theme.title,
    WizardContextKeys.description: theme.description,
  };
}
