import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/data/data_sources/memory_deck_loader.dart';
import '../../../../core/domain/stores/deck_customization_store.dart';
import '../../../../core/result.dart';
import '../../../editor/domain/stores/deck_document_store.dart';
import '../../quick_agent/core/env_config.dart';
import '../../quick_agent/core/engine/services/generation_progress.dart';
import '../../quick_agent/domain/commands/generate_deck_command.dart';
import '../core/ai/debug_generation_presets.dart';
import '../core/ai/services/prompt_builder.dart';
import '../core/ui/components/sd_custom.dart';
import '../core/utils/color_utils.dart';
import 'generation_progress_view.dart';
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
            customizationStore: context.read<DeckCustomizationStore?>(),
          ),
          dispose: (_, command) => command.dispose(),
        ),
      ],
      child: const _WizardWorkspace(),
    );
  }
}

class _WizardWorkspace extends StatefulWidget {
  const _WizardWorkspace();

  @override
  State<_WizardWorkspace> createState() => _WizardWorkspaceState();
}

class _WizardWorkspaceState extends State<_WizardWorkspace> {
  DeckDocumentStore? _documentStore;
  String? _lastPresentedMarkdown;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final documentStore = context.read<DeckDocumentStore>();
    if (identical(documentStore, _documentStore)) return;

    _documentStore?.removeListener(_openGeneratedDeck);
    _documentStore = documentStore..addListener(_openGeneratedDeck);
  }

  @override
  void dispose() {
    _documentStore?.removeListener(_openGeneratedDeck);
    super.dispose();
  }

  void _openGeneratedDeck() {
    final markdown = _documentStore?.markdown ?? '';
    if (markdown.isEmpty || markdown == _lastPresentedMarkdown) return;

    _lastPresentedMarkdown = markdown;
    context.read<MemoryDeckLoader>().updateMarkdown(markdown);
    context.push('/present/0');
  }

  @override
  Widget build(BuildContext context) {
    final command = context.watch<GenerateDeckCommand>();
    final result = command.result;

    return Scaffold(
      backgroundColor: $background.resolve(context),
      body: Stack(
        children: [
          SafeArea(
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
          if (kDebugMode)
            Positioned.fill(
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, right: 16),
                    child: _DebugGenerationMenu(command: command),
                  ),
                ),
              ),
            ),
          if (result case Failure(:final error))
            Positioned(
              left: 32,
              right: 32,
              bottom: 24,
              child: _GenerationErrorBanner(message: error.toString()),
            ),
          if (command.running)
            Positioned.fill(
              child: _GenerationProgressOverlay(phase: command.phase),
            ),
        ],
      ),
    );
  }
}

class _DebugGenerationMenu extends StatelessWidget {
  const _DebugGenerationMenu({required this.command});

  final GenerateDeckCommand command;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          $surfaceSecondary.resolve(context),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
        side: WidgetStatePropertyAll(
          BorderSide(color: $border.resolve(context)),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      menuChildren: [
        for (final preset in debugGenerationPresets)
          MenuItemButton(
            onPressed: command.running ? null : () => _generate(preset),
            style: ButtonStyle(
              alignment: Alignment.centerLeft,
              foregroundColor: WidgetStatePropertyAll(
                $foreground.resolve(context),
              ),
              overlayColor: WidgetStatePropertyAll(
                $surfaceTertiary.resolve(context),
              ),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            child: _DebugGenerationPresetContent(preset: preset),
          ),
      ],
      builder: (context, controller, child) {
        return HeroButton(
          label: 'Debug generate',
          iconLeft: Icons.bug_report_outlined,
          size: .sm,
          variant: .ghost,
          onPressed: command.running
              ? null
              : () =>
                    controller.isOpen ? controller.close() : controller.open(),
        );
      },
    );
  }

  void _generate(DebugGenerationPreset preset) {
    final prompt = buildPromptFromWizardContext(preset.context);
    unawaited(command(prompt));
  }
}

class _DebugGenerationPresetContent extends StatelessWidget {
  const _DebugGenerationPresetContent({required this.preset});

  final DebugGenerationPreset preset;

  @override
  Widget build(BuildContext context) {
    final palette = preset.context.colors ?? const <String>[];
    final foreground = $foreground.resolve(context);
    final muted = $muted.resolve(context);

    return SizedBox(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preset.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            preset.description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final color in palette)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SdColorCircle(color: hexToColor(color)),
                ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  preset.context.style ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GenerationProgressOverlay extends StatelessWidget {
  const _GenerationProgressOverlay({required this.phase});

  final GenerationPhase phase;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: $background.resolve(context).withValues(alpha: 0.97),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: GenerationProgressView(phase: phase),
            ),
          ),
        ),
      ),
    );
  }
}

class _GenerationErrorBanner extends StatelessWidget {
  const _GenerationErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: $danger.resolve(context).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: $danger.resolve(context)),
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
