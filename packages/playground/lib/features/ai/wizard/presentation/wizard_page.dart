import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:provider/provider.dart';

import '../../../editor/domain/files/deck_file_repository.dart';
import '../../image_generation/image_generator.dart';
import '../../quick_agent/core/env_config.dart';
import '../domain/commands/create_wizard_deck_command.dart';
import 'wizard_view.dart';

/// Isolated host for exercising the conversational Wizard without the editor.
///
/// Successful generation creates a persistent deck and opens it in the editor.
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
        ListenableProvider<CreateWizardDeckCommand>(
          create: (context) => CreateWizardDeckCommand(
            repository: context.read<DeckFileRepository>(),
            imageGenerator: context.read<ImageGenerator>(),
          ),
          dispose: (_, command) => command.dispose(),
        ),
      ],
      child: Scaffold(
        backgroundColor: $background.resolve(context),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: const Padding(
                padding: EdgeInsets.all(32),
                child: WizardView(),
              ),
            ),
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
