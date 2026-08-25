import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/domain/design/presentation_image_style_catalog.dart';
import '../../../../image_generation/image_style_preview_coordinator.dart';
import '../schemas/genui_action_schema.dart';
import '../schemas/wizard_context_keys.dart';
import '../../ui/ui.dart';
import 'ask_user_question_cards.dart';
import 'catalog_question_step.dart';
import 'component_schema.dart';
import 'typed_catalog_item.dart';
import 'user_action_dispatch.dart';

part 'ask_user_image_style.ack.dart';
part 'ask_user_image_style.g.dart';

/// The model owns only the question copy. The application owns the exact
/// preview subject, styles, generation, and versioned selection payload.
@AckType(name: 'AskUserImageStyle')
final _askUserImageStyleSchema = Ack.object({
  'question': Ack.string().describe('The question to display to the user'),
  'description': Ack.string().optional().describe(
    'Additional context or instructions',
  ),
  'action': actionSchema,
}).describe('An application-owned generated image-style selection step.');

CatalogItem askUserImageStyleFor(
  PresentationImageStyleCatalog imageStyleCatalog,
) {
  for (final id in featuredPresentationImageStyleIds) {
    if (imageStyleCatalog.current(id) == null) {
      throw ArgumentError('Missing featured image style "$id".');
    }
  }

  return typedCatalogItem<AskUserImageStyle>(
    name: 'AskUserImageStyle',
    dataSchema: componentSchema(_askUserImageStyleSchema.toJsonSchemaBuilder()),
    exampleData: [
      () => const JsonEncoder.withIndent('  ').convert([
        {
          'id': 'root',
          'component': 'AskUserImageStyle',
          'question': 'Choose an artwork direction',
          'description':
              'Compare the same idea across three generated treatments.',
          'action': {'name': 'submit_answer', 'context': <Object?>[]},
        },
      ]),
    ],
    parse: AskUserImageStyle.parse,
    widgetBuilder: (context, data) =>
        _AskUserImageStyleContent(data: data, itemContext: context),
  );
}

class _AskUserImageStyleContent extends StatefulWidget {
  const _AskUserImageStyleContent({
    required this.data,
    required this.itemContext,
  });

  final AskUserImageStyle data;
  final CatalogItemContext itemContext;

  @override
  State<_AskUserImageStyleContent> createState() =>
      _AskUserImageStyleContentState();
}

class _AskUserImageStyleContentState extends State<_AskUserImageStyleContent> {
  PresentationImageStyleDescriptor? _selectedStyle;

  bool get _canSubmit => _selectedStyle != null;

  void _submit() => submitCatalogActionIfValid(
    canSubmit: _canSubmit,
    itemContext: widget.itemContext,
    action: widget.data.action,
    contextBuilder: () => buildImageStyleSelectionContext(_selectedStyle!),
  );

  @override
  Widget build(BuildContext context) {
    final coordinator = context.watch<ImageStylePreviewCoordinator>();
    final previews = coordinator.previews;

    return CatalogQuestionStep(
      question: widget.data.question,
      body: previews.isEmpty
          ? const SdBody('Preparing artwork directions…')
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: .stretch,
                spacing: 16,
                children: [
                  for (final preview in previews)
                    Expanded(
                      child: ImageStyleOptionCard(
                        key: ValueKey('wizard-image-style-${preview.style.id}'),
                        style: preview.style,
                        imageBytes: preview.bytes,
                        isLoading: preview.status == .loading,
                        hasFailed: preview.status == .failed,
                        selected: _selectedStyle?.id == preview.style.id,
                        onTap: () {
                          setState(() => _selectedStyle = preview.style);
                        },
                        onRetry: preview.status == .failed
                            ? () => coordinator.retry(preview.style.id)
                            : null,
                      ),
                    ),
                ],
              ),
            ),
      onSubmit: _submit,
      description: widget.data.description,
      canSubmit: _canSubmit,
    );
  }
}

/// Maps a catalog descriptor into the exact ID/version Wizard contract.
Map<String, dynamic> buildImageStyleSelectionContext(
  PresentationImageStyleDescriptor style,
) {
  return {
    WizardContextKeys.imageStyleId: style.id,
    WizardContextKeys.imageStyleVersion: style.version,
    WizardContextKeys.title: style.title,
  };
}
