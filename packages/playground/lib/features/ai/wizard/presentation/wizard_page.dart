import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/domain/stores/deck_customization_store.dart';
import '../../../editor/domain/stores/deck_document_store.dart';
import '../../quick_agent/core/env_config.dart';
import '../../quick_agent/domain/commands/generate_deck_command.dart';
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
      child: Scaffold(
        backgroundColor: $background.resolve(context),
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: const Padding(
                    padding: EdgeInsets.all(32),
                    child: WizardView(),
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
