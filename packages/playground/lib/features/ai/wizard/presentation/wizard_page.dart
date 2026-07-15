import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/domain/stores/deck_customization_store.dart';
import '../../../../core/data/data_sources/memory_deck_loader.dart';
import '../../../editor/domain/stores/deck_document_store.dart';
import '../../quick_agent/core/engine/services/deck_generator_service.dart';
import '../../quick_agent/core/env_config.dart';
import '../../quick_agent/domain/generated_deck_result_applier.dart';
import '../chat/chat_conversation_profile.dart';
import '../core/ai/services/ai_conversation_viewmodel.dart';
import '../core/viewmodel_scope.dart';
import 'wizard_generation_controller.dart';
import 'wizard_generation_status.dart';
import 'wizard_outline_review.dart';
import 'wizard_view.dart';

/// Isolated host for exercising the conversational Wizard without the editor.
///
/// Generated Markdown is kept in memory so opening this screen never requests a
/// deck-storage folder. The production integration can provide its own document
/// destination when the Wizard is embedded outside the playground.
class WizardPage extends StatelessWidget {
  const WizardPage({this.isConfigured, this.generationService, super.key});

  /// Overrides environment detection in tests and previews.
  final bool? isConfigured;

  /// Overrides the live Gemini-backed service in tests and previews.
  final DeckGeneratorService? generationService;

  @override
  Widget build(BuildContext context) {
    final hasApiKey = isConfigured ?? EnvConfig.hasGeminiApiKey;

    if (!hasApiKey) {
      return const _MissingApiKeyView();
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeckDocumentStore(markdown: '')),
        ChangeNotifierProvider<WizardGenerationController>(
          create: (context) => WizardGenerationController(
            service:
                generationService ??
                DeckGeneratorService(apiKey: EnvConfig.geminiApiKey),
            applyResult: (result) => applyGeneratedDeckResult(
              result: result,
              documentStore: Provider.of<DeckDocumentStore>(
                context,
                listen: false,
              ),
              deckLoader: Provider.of<MemoryDeckLoader>(context, listen: false),
              customizationStore: Provider.of<DeckCustomizationStore>(
                context,
                listen: false,
              ),
            ),
          ),
        ),
      ],
      child: ViewModelScope<AiConversationViewModel>(
        create: () {
          // ViewModelScope owns and disposes the created conversation model.
          return AiConversationViewModel(profile: chatConversationProfile());
        },
        child: const _WizardExperience(),
      ),
    );
  }
}

class _WizardExperience extends StatelessWidget {
  const _WizardExperience();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WizardGenerationController>();
    final overlay = switch (controller.stage) {
      WizardGenerationStage.setup => null,
      WizardGenerationStage.planning ||
      WizardGenerationStage.composing => _CenteredScrollable(
        child: WizardGenerationStatus(
          kind: WizardGenerationStatusKind.running,
          progress: controller.progress,
          onCancel: controller.cancel,
        ),
      ),
      WizardGenerationStage.outlineReview => WizardOutlineReview(
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
      WizardGenerationStage.failed => _CenteredScrollable(
        child: WizardGenerationStatus(
          kind: WizardGenerationStatusKind.failed,
          errorMessage: controller.errorMessage,
          planAvailable: controller.plan != null,
          onRetry: () {
            unawaited(controller.retry());
          },
          backLabel: controller.plan != null ? 'Edit outline' : 'Back to setup',
          onBack: controller.plan != null
              ? controller.returnToOutline
              : controller.reset,
        ),
      ),
      WizardGenerationStage.completed => _CenteredScrollable(
        child: WizardGenerationStatus(
          kind: WizardGenerationStatusKind.completed,
          noticeMessage: _partialResultNotice(controller.result),
          slideCount: controller.result?.slides.length,
          failedSlideCount: controller.result?.slideFailures.length ?? 0,
          elapsed: controller.elapsed,
          onRetryFailed: () {
            unawaited(controller.retryFailedSlides());
          },
          onPresent: () => context.push('/present/0'),
          onEditOutline: controller.editOutline,
          onStartOver: () {
            controller.reset();
            ViewModelScope.of<AiConversationViewModel>(
              context,
            ).restartConversation();
          },
        ),
      ),
    };

    return Scaffold(
      backgroundColor: $background.resolve(context),
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
                      fit: StackFit.expand,
                      children: [
                        Offstage(
                          offstage:
                              controller.stage != WizardGenerationStage.setup,
                          child: const WizardView(),
                        ),
                        ?overlay,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (kDebugMode)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  tooltip: 'Generation lab',
                  onPressed: () => context.push('/debug/generation'),
                  icon: const Icon(Icons.science_outlined),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String? _partialResultNotice(DeckGenerationResult? result) {
  if (result == null || !result.isPartial) return null;
  final failed = result.slideFailures.length;
  return '${result.slides.length} slides are ready. '
      '$failed ${failed == 1 ? 'slide needs' : 'slides need'} another pass.';
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
