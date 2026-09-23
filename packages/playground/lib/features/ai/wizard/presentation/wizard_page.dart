import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/domain/design/presentation_image_style_catalog.dart';
import '../../../../core/domain/stores/deck_customization_store.dart';
import '../../../../core/data/data_sources/deck_library_asset_store.dart';
import '../../../../core/domain/stores/deck_document_store.dart';
import '../../../library/domain/deck_library.dart';
import '../../../library/domain/deck_library_controller.dart';
import '../../../library/domain/saved_deck.dart';
import '../../../library/presentation/save_deck_dialog.dart';
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
/// Generated Markdown is kept in memory: results are applied straight to the
/// in-memory document and preview stores, and a deck-storage folder is only
/// requested later, when the reader chooses to save.
class WizardPage extends StatelessWidget {
  const WizardPage({
    this.isConfigured,
    this.generationService,
    this.imageGenerator,
    this.imageGenerationEnabled,
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
              documentStore: Provider.of<DeckDocumentStore>(
                context,
                listen: false,
              ),
              deckLoader: Provider.of(context, listen: false),
              assetCacheStore: Provider.of<DeckLibraryAssetStore>(
                context,
                listen: false,
              ),
              customizationStore: Provider.of<DeckCustomizationStore>(
                context,
                listen: false,
              ),
            );

            final library = Provider.of<DeckLibraryController>(
              context,
              listen: false,
            );

            return WizardGenerationController(
              service:
                  generationService ??
                  DeckGeneratorService(
                    apiKey: EnvConfig.geminiApiKey,
                    imageGenerator: finalImageGenerator,
                  ),
              applyResult: (result, {required isValid}) {
                // A generated deck owns the runtime from here. The saved deck
                // that was open must stop answering for artwork, or a new
                // image could resolve to the old deck's file of the same name.
                library.releaseOpenDeck();

                return resultApplier.apply(result, isValid: isValid);
              },
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
          child: const _WizardExperience(),
        ),
      ),
    );
  }
}

class _WizardExperience extends StatefulWidget {
  const _WizardExperience();

  @override
  State<_WizardExperience> createState() => _WizardExperienceState();
}

class _WizardExperienceState extends State<_WizardExperience> {
  /// Saves the deck the Wizard just produced, under a name the reader picks.
  ///
  /// Nothing is written until the dialog is confirmed, and a deck that is
  /// saved twice becomes two decks rather than one overwritten one.
  Future<void> _save(WizardGenerationController controller) async {
    final result = controller.result;
    if (result == null) return;
    final library = context.read<DeckLibraryController>();
    final name = await SaveDeckDialog.show(
      context,
      name: controller.plan?.topic ?? 'Untitled deck',
    );
    if (name == null || !mounted) return;

    await library.save(
      name: name,
      images: result.generatedImages,
      theme: switch (result.theme) {
        final theme? => SavedDeckTheme(
          id: theme.descriptor.id,
          version: theme.descriptor.version,
          density: theme.density,
        ),
        _ => null,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WizardGenerationController>();
    final library = context.watch<DeckLibraryController>();
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
              library.errorMessage ??
              _saveNotice(library.lastSave) ??
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
          onSave: library.canSave ? () => unawaited(_save(controller)) : null,
          onOpenSavedDecks: () => context.push('/decks'),
          saveLabel: library.lastSave == null
              ? 'Save deck'
              : 'Save another copy',
          isSaving: library.isBusy,
        ),
      ),
    };

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
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
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => context.push('/decks'),
                tooltip: 'Saved decks',
                icon: const Icon(Icons.folder_outlined),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: $background.resolve(context),
    );
  }
}

/// Names what a save wrote, including artwork that could not come along.
String? _saveNotice(DeckSaveOutcome? outcome) {
  if (outcome == null) return null;
  if (outcome.isComplete) {
    return 'Saved "${outcome.ref.name}" to your SuperDeck folder.';
  }
  final missing = outcome.missingAssetKeys.length;

  return 'Saved "${outcome.ref.name}", without $missing '
      '${missing == 1 ? 'image' : 'images'} that had no artwork to write.';
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
