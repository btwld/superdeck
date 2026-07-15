import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/domain/stores/deck_customization_store.dart';
import '../../../../core/result.dart';
import '../../../editor/domain/stores/deck_document_store.dart';
import '../../quick_agent/core/env_config.dart';
import '../../quick_agent/domain/commands/generate_deck_command.dart';
import 'wizard_generation_status.dart';
import 'wizard_view.dart';

/// Isolated host for exercising the conversational Wizard without the editor.
///
/// Generated Markdown is kept in memory so opening this screen never requests a
/// deck-storage folder. The production integration can provide its own document
/// destination when the Wizard is embedded outside the playground.
class WizardPage extends StatelessWidget {
  const WizardPage({this.isConfigured, super.key});

  /// Overrides environment detection in tests and previews.
  final bool? isConfigured;

  @override
  Widget build(BuildContext context) {
    final hasApiKey = isConfigured ?? EnvConfig.hasGeminiApiKey;

    if (!hasApiKey) {
      return const _MissingApiKeyView();
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeckDocumentStore(markdown: '')),
        ListenableProvider<GenerateDeckCommand>(
          create: (context) => GenerateDeckCommand(
            documentStore: context.read<DeckDocumentStore>(),
            customizationStore: context.read<DeckCustomizationStore>(),
          ),
          dispose: (_, command) => command.dispose(),
        ),
      ],
      child: const _WizardExperience(),
    );
  }
}

class _WizardExperience extends StatelessWidget {
  const _WizardExperience();

  @override
  Widget build(BuildContext context) {
    final command = context.watch<GenerateDeckCommand>();
    final result = command.result;

    final Widget? status;
    if (command.running) {
      status = WizardGenerationStatus(
        kind: WizardGenerationStatusKind.running,
        progress: command.progress,
      );
    } else if (result case Failure(:final error)) {
      status = WizardGenerationStatus(
        kind: WizardGenerationStatusKind.failed,
        errorMessage: error.toString(),
        onDismiss: command.clearResult,
      );
    } else if (command.completed) {
      status = WizardGenerationStatus(
        kind: WizardGenerationStatusKind.completed,
        noticeMessage: command.completionNotice,
        onDismiss: command.clearResult,
      );
    } else {
      status = null;
    }

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
                          offstage: status != null,
                          child: const WizardView(),
                        ),
                        if (status != null)
                          Positioned.fill(
                            child: ColoredBox(
                              color: $background.resolve(context),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 620,
                                  ),
                                  child: status,
                                ),
                              ),
                            ),
                          ),
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
