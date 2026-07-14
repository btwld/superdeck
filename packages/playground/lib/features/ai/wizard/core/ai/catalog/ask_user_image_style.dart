import 'dart:async';
import 'dart:typed_data';

import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/domain/generated_image_asset.dart';
import '../../../../image_generation/image_generator.dart';
import '../prompts/image_style_prompts.dart';
import '../schemas/genui_action_schema.dart';
import '../schemas/wizard_context_keys.dart';
import '../../debug_logger.dart';
import '../../ui/ui.dart';
import 'ask_user_question_cards.dart';
import 'catalog_question_step.dart';
import 'component_schema.dart';
import 'typed_catalog_item.dart';
import 'user_action_dispatch.dart';

part 'ask_user_image_style.g.dart';

@AckType(name: 'AskUserImageStyle')
final _askUserImageStyleSchema = Ack.object({
  'question': Ack.string().describe('The question to display to the user'),
  'description': Ack.string().optional().describe(
    'Additional context or instructions',
  ),
  'subject': Ack.string().describe(
    'One topic-specific visual subject shared by every preview',
  ),
  'imageStyles': Ack.list(Ack.enumValues<ImageStyle>(ImageStyle.values))
      .minItems(3)
      .maxItems(3)
      .unique()
      .describe(ImageStyle.schemaDescription(count: 3)),
  'action': actionSchema,
}).describe('A curated image-style question with three generated previews.');

final askUserImageStyle = typedCatalogItem<AskUserImageStyleType>(
  name: 'AskUserImageStyle',
  dataSchema: componentSchema(_askUserImageStyleSchema.toJsonSchemaBuilder()),
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "AskUserImageStyle",
          "question": "Choose an artwork style",
          "description": "Preview one subject in three visual directions.",
          "subject": "a small team mapping a bold new idea",
          "imageStyles": ["watercolor", "minimalist", "gradient"],
          "action": {"name": "submit_answer", "context": []}
        }
      ]
    ''',
  ],
  parse: AskUserImageStyleType.parse,
  widgetBuilder: (context, data) =>
      _AskUserImageStyleContent(data: data, itemContext: context),
);

class _AskUserImageStyleContent extends StatefulWidget {
  const _AskUserImageStyleContent({
    required this.data,
    required this.itemContext,
  });

  final AskUserImageStyleType data;
  final CatalogItemContext itemContext;

  @override
  State<_AskUserImageStyleContent> createState() =>
      _AskUserImageStyleContentState();
}

class _AskUserImageStyleContentState extends State<_AskUserImageStyleContent> {
  final Map<int, Uint8List> _generatedImages = {};
  final Set<int> _loadingImages = {};
  final Set<int> _failedImages = {};

  ImageStyle? _selectedStyle;
  int _generationId = 0;

  bool get _canSubmit => _selectedStyle != null;

  @override
  void initState() {
    super.initState();
    unawaited(_generatePreviews());
  }

  @override
  void didUpdateWidget(covariant _AskUserImageStyleContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.subject == widget.data.subject &&
        listEquals(oldWidget.data.imageStyles, widget.data.imageStyles)) {
      return;
    }
    _reset();
    unawaited(_generatePreviews());
  }

  @override
  void dispose() {
    _generationId++;
    super.dispose();
  }

  Future<void> _generatePreviews() async {
    final generationId = ++_generationId;
    final styles = widget.data.imageStyles;
    if (styles.isEmpty) return;

    setState(() {
      _loadingImages.addAll(styles.asMap().keys);
      _failedImages.clear();
    });

    final generator = context.read<ImageGenerator>();
    for (final entry in styles.asMap().entries) {
      if (!_isCurrent(generationId)) return;
      await _generatePreview(
        generator: generator,
        generationId: generationId,
        index: entry.key,
        style: entry.value,
      );
    }
  }

  Future<void> _retryPreview(int index) async {
    final styles = widget.data.imageStyles;
    if (index < 0 || index >= styles.length) return;

    final generationId = _generationId;
    setState(() {
      _failedImages.remove(index);
      _loadingImages.add(index);
    });
    await _generatePreview(
      generator: context.read<ImageGenerator>(),
      generationId: generationId,
      index: index,
      style: styles[index],
    );
  }

  Future<void> _generatePreview({
    required ImageGenerator generator,
    required int generationId,
    required int index,
    required ImageStyle style,
  }) async {
    final prompt = buildPresentationImagePrompt(
      style.buildPrompt(widget.data.subject),
    );
    debugLog.log('IMG', 'Generating Wizard preview ${style.name}');
    final result = await generateImageSafely(
      generator,
      ImageGenerationRequest(
        prompt: prompt,
        aspectRatio: GeneratedImageAspectRatio.preview16x9,
      ),
    );
    if (!_isCurrent(generationId)) return;

    setState(() {
      _loadingImages.remove(index);
      switch (result) {
        case ImageGenerationSuccess(:final bytes):
          _generatedImages[index] = bytes;
          _failedImages.remove(index);
        case ImageGenerationFailure(:final message):
          debugLog.log('IMG', 'Wizard preview failed: $message');
          _failedImages.add(index);
      }
    });
  }

  void _reset() {
    _generationId++;
    _selectedStyle = null;
    _generatedImages.clear();
    _loadingImages.clear();
    _failedImages.clear();
  }

  bool _isCurrent(int generationId) => mounted && generationId == _generationId;

  Map<String, dynamic> _buildActionContext() {
    final style = _selectedStyle;
    if (style == null) return {};
    return {
      WizardContextKeys.imageStyleId: style.id,
      WizardContextKeys.imageStyleName: style.title,
      WizardContextKeys.imageStyleDescription: style.description,
      WizardContextKeys.message: style.title,
    };
  }

  void _submit() => submitCatalogActionIfValid(
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
      onSubmit: _submit,
    );
  }

  Widget _buildOptions() {
    final styles = widget.data.imageStyles;
    if (styles.isEmpty) {
      return const SdBody('No image styles configured');
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: styles.asMap().entries.map((entry) {
          final index = entry.key;
          return Expanded(
            child: ImageStyleOptionCard(
              key: ValueKey('wizard-image-style-${entry.value.id}'),
              style: entry.value,
              imageBytes: _generatedImages[index],
              isLoading: _loadingImages.contains(index),
              hasFailed: _failedImages.contains(index),
              selected: _selectedStyle == entry.value,
              onTap: () => setState(() => _selectedStyle = entry.value),
              onRetry: _failedImages.contains(index)
                  ? () => unawaited(_retryPreview(index))
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}
