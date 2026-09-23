import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/data/data_sources/memory_asset_cache_store.dart';
import '../../../../core/domain/design/presentation_image_style_catalog.dart';
import '../../../../core/domain/stores/deck_customization_store.dart';
import '../../../export/data/deck_export_saver.dart';
import '../../../export/domain/deck_export.dart';
import '../../generation/core/engine/services/deck_generator_service.dart';
import '../../generation/core/env_config.dart';
import '../../generation/domain/generated_deck_result_applier.dart';
import '../../image_generation/image_generator.dart';
import '../../image_generation/image_style_preview_coordinator.dart';
import '../chat/chat_conversation_profile.dart';
import '../core/ai/services/ai_conversation_viewmodel.dart';
import '../core/viewmodel_scope.dart';
import 'wizard_generation_controller.dart';
import 'wizard_generation_status.dart';
import 'wizard_outline_review.dart';
import 'wizard_view.dart';

/// Host for the conversational Wizard, the app's only authoring flow.
///
/// Generated decks stay in memory; exporting writes one out as a SuperDeck
/// project.
class WizardPage extends StatelessWidget {
  const WizardPage({
    this.isConfigured,
    this.generationService,
    this.imageGenerator,
    this.imageGenerationEnabled,
    this.exportSaver = saveDeckExportAsZip,
    super.key,
  });

  /// Overrides environment detection in tests and previews.
  final bool? isConfigured;

  /// Overrides the live Gemini-backed service in tests and previews.
  final DeckGeneratorService? generationService;

  /// Overrides the live Flash Lite image provider in tests and previews.
  final ImageGenerator? imageGenerator;

  /// Overrides the debug-on, release-opt-in image rollout policy.
  final bool? imageGenerationEnabled;

  /// Writes an exported deck. Tests replace the platform save dialog.
  final DeckExportSaver exportSaver;

  @override
  Widget build(BuildContext context) {
    final hasApiKey = isConfigured ?? EnvConfig.hasGeminiApiKey;

    if (!hasApiKey) {
      return const _MissingApiKeyView();
    }
    final imagesEnabled =
        imageGenerationEnabled ?? EnvConfig.wizardImageGenerationEnabled;
    final imageStyles = PresentationImageStyleCatalog.withDefaults();
    final previewImageGenerator = !imagesEnabled
        ? const UnavailableImageGenerator()
        : (imageGenerator ??
              (EnvConfig.hasGeminiApiKey
                  ? DartanticImageGenerator(apiKey: EnvConfig.geminiApiKey)
                  : const UnavailableImageGenerator()));
    final finalImageGenerator = !imagesEnabled
        ? null
        : (imageGenerator ??
              (EnvConfig.hasGeminiApiKey
                  ? DartanticImageGenerator(
                      apiKey: EnvConfig.geminiApiKey,
                      modelName: geminiImageGenerationModel,
                    )
                  : const UnavailableImageGenerator()));

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ImageStylePreviewCoordinator(
            generator: previewImageGenerator,
            catalog: imageStyles,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) {
            final resultApplier = GeneratedDeckResultApplier(
              deckLoader: Provider.of(context, listen: false),
              assetCacheStore: Provider.of<MemoryAssetCacheStore>(
                context,
                listen: false,
              ),
              customizationStore: Provider.of<DeckCustomizationStore>(
                context,
                listen: false,
              ),
            );

            return WizardGenerationController(
              service:
                  generationService ??
                  DeckGeneratorService(
                    apiKey: EnvConfig.geminiApiKey,
                    imageGenerator: finalImageGenerator,
                  ),
              applyResult: resultApplier.apply,
            );
          },
        ),
      ],
      child: Builder(
        builder: (context) => ViewModelScope(
          create: () {
            // ViewModelScope owns and disposes the conversation model. The
            // Wizard provider owns and disposes the preview coordinator.
            return AiConversationViewModel(
              profile: chatConversationProfile(imageStyleCatalog: imageStyles),
              imageStylePreviews: imagesEnabled ? context.read() : null,
              imageStyleEnabled: imagesEnabled,
            );
          },
          child: _WizardExperience(exportSaver: exportSaver),
        ),
      ),
    );
  }
}

class _WizardExperience extends StatefulWidget {
  const _WizardExperience({required this.exportSaver});

  final DeckExportSaver exportSaver;

  @override
  State<_WizardExperience> createState() => _WizardExperienceState();
}

class _WizardExperienceState extends State<_WizardExperience> {
  bool _isExporting = false;

  /// What the last export did, for the result it exported.
  ({DeckGenerationResult result, String message})? _exportNotice;

  /// Writes the deck the Wizard just produced to wherever the reader picks.
  Future<void> _export(DeckGenerationResult result) async {
    final export = DeckExport.fromDeck(
      slides: result.slides,
      images: result.generatedImages,
    );
    setState(() => _isExporting = true);
    String? message;
    try {
      final saved = await widget.exportSaver(export);
      if (saved) message = 'Exported "${export.name}".';
    } catch (error) {
      message = 'The deck could not be exported: $error';
    }
    if (!mounted) return;
    setState(() {
      _isExporting = false;
      if (message != null) _exportNotice = (result: result, message: message);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WizardGenerationController>();
    final result = controller.result;
    final exportNotice = identical(_exportNotice?.result, result)
        ? _exportNotice?.message
        : null;
    final overlay = switch (controller.stage) {
      .setup => null,
      .planning || .composing => _CenteredScrollable(
        child: WizardGenerationStatus(
          kind: .running,
          progress: controller.progress,
          onCancel: controller.cancel,
        ),
      ),
      .outlineReview => WizardOutlineReview(
        plan: controller.plan!,
        planRevision: controller.planRevision,
        onSlideChanged: (index, title, assertion) =>
            controller.updateSlide(index, title: title, assertion: assertion),
        onBack: controller.reset,
        onRegenerate: () {
          unawaited(controller.regenerateOutline());
        },
        onApprove: () {
          unawaited(controller.generateSlides());
        },
      ),
      .failed => _CenteredScrollable(
        child: WizardGenerationStatus(
          kind: .failed,
          errorMessage: controller.errorMessage,
          planAvailable: controller.plan != null,
          onRetry: () {
            unawaited(controller.retry());
          },
          onBack: controller.plan != null
              ? controller.returnToOutline
              : controller.reset,
          backLabel: controller.plan != null ? 'Edit outline' : 'Back to setup',
        ),
      ),
      .completed => _CenteredScrollable(
        child: WizardGenerationStatus(
          kind: .completed,
          noticeMessage:
              exportNotice ??
              _completionNotice(controller.result, controller.applyNotice),
          slideCount: controller.result?.slides.length,
          failedSlideCount: controller.result?.slideFailures.length ?? 0,
          artworkCount: controller.result?.generatedImageCount ?? 0,
          failedArtworkCount: controller.result?.failedImageCount ?? 0,
          elapsed: controller.elapsed,
          onPresent: () => context.push('/present/0'),
          onRetryFailed: () {
            unawaited(controller.retryFailedSlides());
          },
          onEditOutline: controller.editOutline,
          onStartOver: () {
            controller.reset();
            ViewModelScope.of<AiConversationViewModel>(
              context,
            ).restartConversation();
          },
          onExport: result == null ? null : () => unawaited(_export(result)),
          isExporting: _isExporting,
        ),
      ),
    };

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: SizedBox(
              width: constraints.constrainWidth(1080),
              height: constraints.maxHeight,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Stack(
                  fit: .expand,
                  children: [
                    Offstage(
                      offstage: controller.stage != .setup,
                      child: const WizardView(),
                    ),
                    ?overlay,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: $background.resolve(context),
    );
  }
}

String? _completionNotice(DeckGenerationResult? result, String? applyNotice) {
  if (result == null) return null;
  final messages = <String>[?applyNotice];
  if (result.isPartial) {
    final failed = result.slideFailures.length;
    messages.add(
      '${result.slides.length} slides are ready. '
      '$failed ${failed == 1 ? 'slide needs' : 'slides need'} another pass.',
    );
  }
  if (result.hasImageFailures) {
    final failed = result.failedImageCount;
    messages.add(
      'Created ${result.generatedImageCount} of '
      '${result.generatedImages.length} planned artworks. '
      '$failed ${failed == 1 ? 'image uses' : 'images use'} a text-first fallback.',
    );
  }

  return messages.isEmpty ? null : messages.join(' ');
}

class _CenteredScrollable extends StatelessWidget {
  const _CenteredScrollable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _MissingApiKeyView extends StatelessWidget {
  const _MissingApiKeyView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: $background.resolve(context),
      body: const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 40),
                SizedBox(height: 16),
                Text(
                  'Google AI API key is not configured',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'Add GOOGLE_AI_API_KEY to the repository .env file, then '
                  'launch with --dart-define-from-file=../../.env.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
