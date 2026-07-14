import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_builder/superdeck_builder.dart';

import '../../../../../core/data/data_sources/memory_deck_loader.dart';
import '../../../../../core/domain/stores/deck_customization_store.dart';
import '../../core/engine/services/deck_generator_service.dart';
import '../../core/engine/services/deck_generation_request.dart';
import '../../core/engine/services/generation_progress.dart';
import '../../core/engine/services/generation_trace.dart';
import '../../core/env_config.dart';
import '../../domain/generated_deck_style_mapper.dart';

class GenerationLabPage extends StatefulWidget {
  const GenerationLabPage({super.key});

  @override
  State<GenerationLabPage> createState() => _GenerationLabPageState();
}

class _GenerationLabPageState extends State<GenerationLabPage> {
  final _traces = <GenerationTraceEvent>[];
  GenerationProgress _progress = const GenerationProgress(GenerationPhase.idle);
  DeckGenerationResult? _result;
  String? _error;
  bool _running = false;
  bool _cancelled = false;

  Future<void> _run(_GenerationPreset preset) async {
    setState(() {
      _cancelled = false;
      _running = true;
      _error = null;
      _result = null;
      _traces.clear();
    });
    final service = DeckGeneratorService(apiKey: EnvConfig.geminiApiKey);
    final result = await service.generate(
      preset.request,
      onProgress: (progress) {
        if (mounted) setState(() => _progress = progress);
      },
      onTrace: (event) {
        if (!_cancelled) _traces.add(event);
      },
      isCancelled: () => _cancelled || !mounted,
    );
    if (!mounted) return;
    if (result.success) {
      _applyResult(result);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (!mounted) return;
    setState(() {
      _running = false;
      _result = result;
      _error = result.error;
    });
  }

  void _applyResult(DeckGenerationResult result) {
    final theme = result.theme!;
    context.read<DeckCustomizationStore>().applyGeneratedStyle(
      theme.toGeneratedDeckStyle(),
    );
    context.read<MemoryDeckLoader>().updateMarkdown(
      const SlideSerializer().serialize(result.slides),
    );
  }

  @override
  void dispose() {
    _cancelled = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('AI generation lab')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final preset in _presets)
                FilledButton.tonal(
                  onPressed: _running || !EnvConfig.hasGeminiApiKey
                      ? null
                      : () => _run(preset),
                  child: Text(preset.label),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (!EnvConfig.hasGeminiApiKey)
            const Text('GOOGLE_AI_API_KEY is not configured.'),
          if (_running)
            LinearProgressIndicator(semanticsLabel: _progress.label),
          if (_running)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_progress.label),
            ),
          if (_error case final error?)
            Text(error, style: const TextStyle(color: Colors.red)),
          if (_result?.success ?? false) ...[
            const SizedBox(height: 24),
            Text(
              'Generated slides',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _SlideGallery(
              configurations: context.read<DeckController>().slides.value,
            ),
          ],
          if (_traces.isNotEmpty) ...[
            const SizedBox(height: 24),
            ExpansionTile(
              title: Text('Trace (${_traces.length} events)'),
              children: [
                SelectableText(
                  const JsonEncoder.withIndent(
                    ' ',
                  ).convert(_traces.map((event) => event.toJson()).toList()),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SlideGallery extends StatelessWidget {
  const _SlideGallery({required this.configurations});

  final List<SlideConfiguration> configurations;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 520,
        childAspectRatio: 16 / 9,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: configurations.length,
      itemBuilder: (context, index) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SlideRenderView(configurations[index]),
      ),
    );
  }
}

final class _GenerationPreset {
  final String label;
  final DeckGenerationRequest request;

  const _GenerationPreset(this.label, this.request);
}

const _presets = [
  _GenerationPreset(
    'Narrative',
    DeckGenerationRequest(
      userIntent:
          'Move from reactive incident response to reliability engineering. '
          'Build a clear story from operational pain to a practical first 30 days.',
      slideCount: 10,
      audience: 'Engineering leaders',
      approach: 'Confident editorial narrative',
      themeId: 'editorial-midnight',
      designDirection: 'Dark navy editorial',
    ),
  ),
  _GenerationPreset(
    'Comparison table',
    DeckGenerationRequest(
      userIntent:
          'Compare build, buy, and partner approaches for analytics. Include '
          'one concise comparison table and a recommendation.',
      slideCount: 15,
      audience: 'Product and engineering decision makers',
      approach: 'Evidence-led decision deck',
      themeId: 'technical-paper',
      designDirection: 'Light warm technical',
    ),
  ),
  _GenerationPreset(
    'Visual elements',
    DeckGenerationRequest(
      userIntent: 'Create a developer-platform launch briefing.',
      slideCount: 20,
      audience: 'Developers and technical leaders',
      approach: 'Bold product launch story',
      themeId: 'bold-product',
      designDirection: 'Bold dark product',
      groundedElements: [
        GroundedGenerationElement(
          type: 'image',
          source:
              'https://images.unsplash.com/photo-1516321318423-f06f85e504b3',
          purpose: 'Ground the platform story in a developer workspace',
        ),
        GroundedGenerationElement(
          type: 'qrcode',
          source: 'https://example.com/developer-platform',
          purpose: 'Let the audience open the developer platform',
        ),
        GroundedGenerationElement(
          type: 'webview',
          source: 'https://example.com',
          purpose: 'Demonstrate the live product surface',
        ),
      ],
    ),
  ),
];
