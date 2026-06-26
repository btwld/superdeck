import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:genui/genui.dart';
import 'package:remix/remix.dart';

import 'user_action_dispatch.dart';
import '../prompts/image_style_prompts.dart';
import '../schemas/genui_action_schema.dart';
import '../schemas/wizard_context_keys.dart';
import '../services/image_generator_service.dart';
import '../../env_config.dart';
import '../../debug_logger.dart';
import '../../ui/ui.dart';

import 'ask_user_question_cards.dart';
import 'catalog_question_step.dart';

part 'ask_user_image_style.g.dart';

typedef ImageGeneratorServiceFactory =
    ImageGeneratorService Function({required String apiKey});

ImageGeneratorServiceFactory _defaultImageGeneratorServiceFactory =
    ({required String apiKey}) {
      return ImageGeneratorService(apiKey: apiKey);
    };

@visibleForTesting
ImageGeneratorServiceFactory imageGeneratorServiceFactory =
    _defaultImageGeneratorServiceFactory;

@visibleForTesting
void resetImageGeneratorServiceFactory() {
  imageGeneratorServiceFactory = _defaultImageGeneratorServiceFactory;
}

// ─────────────────────────────────── SCHEMA ───────────────────────────────────

/// Schema for AskUserImageStyle component.
///
/// Displays a question with image style options that generate preview images.
@AckType(name: 'AskUserImageStyle')
final _askUserImageStyleSchema =
    Ack.object({
      'question': Ack.string().describe('The question to display to the user'),
      'description': Ack.string().optional().describe(
        'Additional context or instructions',
      ),
      'subject': Ack.string().describe(
        'Visual subject for image generation, shared across all styles',
      ),
      'imageStyles': Ack.list(
        Ack.enumValues<ImageStyle>(
          ImageStyle.values,
        ).describe('Image style ID'),
      ).describe(ImageStyle.schemaDescription(count: 3)),
      'action': actionSchema,
    }).describe(
      'A question with image style options. Generates preview images for each style.',
    );

// ─────────────────────────────────── CATALOG ITEM ───────────────────────────────────

/// AskUserImageStyle catalog component for image style selection with previews.
final askUserImageStyle = CatalogItem(
  name: 'AskUserImageStyle',
  dataSchema: _askUserImageStyleSchema.toJsonSchemaBuilder(),
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "AskUserImageStyle": {
              "question": "Choose an image style",
              "description": "Select the visual direction for imagery.",
              "subject": "solar system with planets",
              "imageStyles": ["watercolor", "minimalist", "gradient"],
              "action": {"name": "submit_answer", "context": []}
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = AskUserImageStyleType.parse(context.data);
    return _AskUserImageStyleContent(data: data, itemContext: context);
  },
);

// ─────────────────────────────────── WIDGET ───────────────────────────────────

class _AskUserImageStyleContent extends StatefulWidget {
  final AskUserImageStyleType data;
  final CatalogItemContext itemContext;

  const _AskUserImageStyleContent({
    required this.data,
    required this.itemContext,
  });

  @override
  State<_AskUserImageStyleContent> createState() =>
      _AskUserImageStyleContentState();
}

class _AskUserImageStyleContentState extends State<_AskUserImageStyleContent> {
  int? _selectedImageStyleIndex;
  ImageStyle? _selectedImageStyle;
  final Map<int, Uint8List> _generatedImages = {};
  final Set<int> _loadingImages = {};
  final Set<int> _failedImages = {};
  String? _imageError;
  int _generationId = 0;

  bool get _canSubmit => _selectedImageStyle != null;

  @override
  void initState() {
    super.initState();
    _generateImages();
  }

  @override
  void didUpdateWidget(covariant _AskUserImageStyleContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    final subjectChanged = oldWidget.data.subject != widget.data.subject;
    final stylesChanged = !_sameStyleIds(
      oldWidget.data.imageStyles,
      widget.data.imageStyles,
    );

    if (subjectChanged || stylesChanged) {
      _resetImageState();
      _generateImages();
    }
  }

  bool _sameStyleIds(List<ImageStyle> a, List<ImageStyle> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].name != b[i].name) return false;
    }
    return true;
  }

  void _resetImageState() {
    _selectedImageStyleIndex = null;
    _selectedImageStyle = null;
    _generatedImages.clear();
    _loadingImages.clear();
    _failedImages.clear();
    _imageError = null;
  }

  bool _isCurrentGeneration(int generationId) => generationId == _generationId;

  void _setImageError(String message, {required int generationId}) {
    if (!mounted || !_isCurrentGeneration(generationId)) return;
    setState(() => _imageError = message);
  }

  Future<void> _generateImages() async {
    final generationId = ++_generationId;
    final subject = widget.data.subject;
    final styles = widget.data.imageStyles;

    if (styles.isEmpty) return;

    if (!EnvConfig.hasGeminiApiKey) {
      _setImageError('API key not configured', generationId: generationId);
      return;
    }

    if (!mounted || !_isCurrentGeneration(generationId)) return;
    final service = imageGeneratorServiceFactory(
      apiKey: EnvConfig.geminiApiKey,
    );

    try {
      setState(() {
        _imageError = null;
        for (var i = 0; i < styles.length; i++) {
          _loadingImages.add(i);
        }
      });

      final futures = styles.asMap().entries.map((entry) async {
        final index = entry.key;
        final style = entry.value;

        final stylePrompt = style.buildPrompt(subject);
        final prompt = ImageGeneratorService.buildPrompt(stylePrompt);
        debugLog.log('IMG', 'Generating $index (${style.name}): $stylePrompt');

        final result = await service.generateImage(prompt);

        if (!mounted || !_isCurrentGeneration(generationId)) return;

        setState(() {
          if (result.success && result.bytes != null) {
            _generatedImages[index] = result.bytes!;
            _failedImages.remove(index);
          } else {
            _failedImages.add(index);
          }
          _loadingImages.remove(index);
        });
      });

      await Future.wait(futures);
    } catch (e) {
      debugLog.error('IMG', 'Failed to generate previews: $e');
      _setImageError('Failed to generate previews', generationId: generationId);
    } finally {
      service.dispose();
    }
  }

  Future<void> _retryImage(int index) async {
    final generationId = _generationId;
    final subject = widget.data.subject;
    final styles = widget.data.imageStyles;
    if (styles.isEmpty) return;
    if (!EnvConfig.hasGeminiApiKey) return;

    if (index >= styles.length) return;

    if (!mounted || !_isCurrentGeneration(generationId)) return;
    final style = styles[index];
    final service = imageGeneratorServiceFactory(
      apiKey: EnvConfig.geminiApiKey,
    );
    setState(() {
      _failedImages.remove(index);
      _loadingImages.add(index);
    });

    try {
      final stylePrompt = style.buildPrompt(subject);
      final prompt = ImageGeneratorService.buildPrompt(stylePrompt);
      debugLog.log('IMG', 'Retrying $index (${style.name}): $stylePrompt');

      final result = await service.generateImage(prompt);

      if (!mounted || !_isCurrentGeneration(generationId)) return;
      setState(() {
        if (result.success && result.bytes != null) {
          _generatedImages[index] = result.bytes!;
        } else {
          _failedImages.add(index);
        }
        _loadingImages.remove(index);
      });
    } catch (e) {
      debugLog.error('IMG', 'Retry failed for $index: $e');
      if (!mounted || !_isCurrentGeneration(generationId)) return;
      setState(() {
        _failedImages.add(index);
        _loadingImages.remove(index);
      });
    } finally {
      service.dispose();
    }
  }

  Map<String, dynamic> _buildActionContext() {
    if (_selectedImageStyle case final style?) {
      return {
        WizardContextKeys.imageStyleId: style.id,
        WizardContextKeys.imageStyleName: style.title,
        WizardContextKeys.imageStyleDescription: style.description,
        WizardContextKeys.message: style.title,
      };
    }
    return {};
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
      body: _buildImageStyles(),
      canSubmit: _canSubmit,
      onSubmit: _submitAction,
    );
  }

  Widget _buildImageStyles() {
    if (_imageError != null) {
      return Center(
        child: SdCaption(
          _imageError!,
          style: TextStyler().color(Colors.red.shade400),
        ),
      );
    }

    final styles = widget.data.imageStyles;

    if (styles.isEmpty) {
      return const SdBody('No valid image styles configured');
    }

    final optionsRow = FlexBoxStyler().row().spacing(16);

    return optionsRow(
      children: styles.asMap().entries.map((entry) {
        final index = entry.key;
        final style = entry.value;
        final isSelected = _selectedImageStyleIndex == index;
        final hasFailed = _failedImages.contains(index);

        return Expanded(
          child: ImageStyleOptionCard(
            style: style,
            imageBytes: _generatedImages[index],
            isLoading: _loadingImages.contains(index),
            hasFailed: hasFailed,
            selected: isSelected,
            onTap: () {
              setState(() {
                _selectedImageStyleIndex = index;
                _selectedImageStyle = style;
              });
            },
            onRetry: hasFailed ? () => _retryImage(index) : null,
          ),
        );
      }).toList(),
    );
  }
}
