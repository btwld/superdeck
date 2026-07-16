import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_builder/superdeck_builder.dart';

import '../../../../../core/data/data_sources/memory_asset_cache_store.dart';
import '../../../../../core/data/data_sources/memory_deck_loader.dart';
import '../../../../../core/domain/design/presentation_image_style_catalog.dart';
import '../../../../../core/domain/design/presentation_theme_catalog.dart';
import '../../../../../core/domain/stores/deck_customization_store.dart';
import '../../../image_generation/image_generator.dart';
import '../../core/engine/schemas/outline_schema.dart';
import '../../core/engine/services/deck_generation_request.dart';
import '../../core/engine/services/deck_generator_service.dart';
import '../../core/engine/services/generation_progress.dart';
import '../../core/engine/services/generation_trace.dart';
import '../../core/env_config.dart';
import '../../domain/generated_deck_style_mapper.dart';

/// Debug-only harness for iterating on planning, artwork, and composition
/// without repeating the conversational Wizard intake.
class GenerationLabPage extends StatefulWidget {
  const GenerationLabPage({
    this.generationService,
    this.isConfigured,
    super.key,
  });

  final DeckGeneratorService? generationService;
  final bool? isConfigured;

  @override
  State<GenerationLabPage> createState() => _GenerationLabPageState();
}

enum _GenerationLabStage { planning, composing }

class _GenerationLabPageState extends State<GenerationLabPage> {
  final _planningTraces = <GenerationTraceEvent>[];
  final _compositionTraces = <GenerationTraceEvent>[];

  late final DeckGeneratorService _service;
  _GenerationPreset _preset = _presets.first;
  GenerationProgress _progress = const GenerationProgress(GenerationPhase.idle);
  DeckPlanType? _plan;
  DeckGenerationResult? _result;
  Duration? _planningDuration;
  Duration? _compositionDuration;
  String? _error;
  _GenerationLabStage? _runningStage;
  bool _cancelled = false;

  bool get _isConfigured => widget.isConfigured ?? EnvConfig.hasGeminiApiKey;

  @override
  void initState() {
    super.initState();
    _service =
        widget.generationService ??
        DeckGeneratorService(
          apiKey: EnvConfig.geminiApiKey,
          imageGenerator: DartanticImageGenerator(
            apiKey: EnvConfig.geminiApiKey,
            modelName: geminiImageGenerationModel,
          ),
        );
  }

  void _selectPreset(_GenerationPreset preset) {
    if (_runningStage != null || identical(_preset, preset)) return;
    setState(() {
      _preset = preset;
      _plan = null;
      _result = null;
      _planningDuration = null;
      _compositionDuration = null;
      _planningTraces.clear();
      _compositionTraces.clear();
      _error = null;
      _progress = const GenerationProgress(GenerationPhase.idle);
    });
  }

  Future<void> _generateStoryBeats() async {
    if (_runningStage != null || !_isConfigured) return;
    setState(() {
      _cancelled = false;
      _runningStage = .planning;
      _error = null;
      _plan = null;
      _result = null;
      _planningDuration = null;
      _compositionDuration = null;
      _planningTraces.clear();
      _compositionTraces.clear();
      _progress = const GenerationProgress(.generatingOutline);
    });

    final timer = Stopwatch()..start();
    final planning = await _service.plan(
      _preset.request,
      onProgress: (progress) {
        if (mounted) setState(() => _progress = progress);
      },
      onTrace: (event) {
        if (!_cancelled) _planningTraces.add(event);
      },
      isCancelled: () => _cancelled || !mounted,
    );
    timer.stop();
    if (!mounted || _cancelled) return;
    setState(() {
      _runningStage = null;
      _planningDuration = timer.elapsed;
      _progress = const GenerationProgress(GenerationPhase.idle);
      _plan = planning.plan;
      _error = planning.error;
    });
  }

  Future<void> _buildSlides() async {
    final plan = _plan;
    if (_runningStage != null || !_isConfigured || plan == null) return;
    setState(() {
      _cancelled = false;
      _runningStage = .composing;
      _error = null;
      _result = null;
      _compositionDuration = null;
      _compositionTraces.clear();
      _progress = const GenerationProgress(.generatingImages);
    });

    final timer = Stopwatch()..start();
    final result = await _service.generateFromPlan(
      _preset.request,
      plan,
      onProgress: (progress) {
        if (mounted) setState(() => _progress = progress);
      },
      onTrace: (event) {
        if (!_cancelled) _compositionTraces.add(event);
      },
      isCancelled: () => _cancelled || !mounted,
    );
    timer.stop();
    if (!mounted || _cancelled) return;
    if (result.slides.isNotEmpty && result.theme != null) {
      await _applyResult(result);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (!mounted) return;
    setState(() {
      _runningStage = null;
      _compositionDuration = timer.elapsed;
      _progress = const GenerationProgress(GenerationPhase.idle);
      _result = result;
      _error = result.error;
    });
  }

  Future<void> _applyResult(DeckGenerationResult result) async {
    final cache = context.read<MemoryAssetCacheStore>();
    final customization = context.read<DeckCustomizationStore>();
    final deckLoader = context.read<MemoryDeckLoader>();
    for (final asset in result.generatedImages) {
      final bytes = asset.bytes;
      if (bytes != null && bytes.isNotEmpty) {
        await cache.write(asset.assetKey, bytes);
      }
    }
    customization.applyGeneratedStyle(result.theme!.toGeneratedDeckStyle());
    deckLoader.updateMarkdown(const SlideSerializer().serialize(result.slides));
  }

  @override
  void dispose() {
    _cancelled = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final plan = _plan;
    final result = _result;
    final running = _runningStage != null;

    return Scaffold(
      appBar: AppBar(title: const Text('AI generation lab')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Test a completed Wizard selection',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          const Text(
            'Generate the story beats once, review them, then rebuild the slides '
            'and artwork without repeating the intake flow.',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final preset in _presets)
                ChoiceChip(
                  label: Text(preset.label),
                  onSelected: running ? null : (_) => _selectPreset(preset),
                  selected: identical(_preset, preset),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _SelectionSummary(preset: _preset),
          const SizedBox(height: 16),
          if (!_isConfigured)
            const Text(
              'GOOGLE_AI_API_KEY is not configured.',
              style: TextStyle(color: Colors.red),
            ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: running || !_isConfigured
                    ? null
                    : () => unawaited(_generateStoryBeats()),
                icon: const Icon(Icons.auto_stories_outlined),
                label: Text(
                  plan == null
                      ? 'Generate story beats'
                      : 'Regenerate story beats',
                ),
              ),
              OutlinedButton.icon(
                onPressed: running || plan == null
                    ? null
                    : () => unawaited(_buildSlides()),
                icon: const Icon(Icons.slideshow_outlined),
                label: Text(result == null ? 'Build slides' : 'Rebuild slides'),
              ),
              if (running)
                TextButton.icon(
                  onPressed: () => setState(() => _cancelled = true),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
                ),
            ],
          ),
          if (running) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(semanticsLabel: _progress.label),
            const SizedBox(height: 8),
            Text(_progress.label),
          ],
          if (_error case final error?) ...[
            const SizedBox(height: 16),
            Text(error, style: const TextStyle(color: Colors.red)),
          ],
          if (_planningDuration != null || _compositionDuration != null) ...[
            const SizedBox(height: 20),
            _TimingSummary(
              planning: _planningDuration,
              composition: _compositionDuration,
              result: result,
              planningTraces: _planningTraces,
              compositionTraces: _compositionTraces,
            ),
          ],
          if (plan != null) ...[
            const SizedBox(height: 28),
            _StoryBeatReview(plan: plan),
          ],
          if (result != null && result.slideFailures.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Unresolved slides',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final failure in result.slideFailures)
              Text(
                '${failure.slideIndex}. ${failure.slideKey}: ${failure.message}',
              ),
          ],
          if (result != null && result.generatedImages.isNotEmpty) ...[
            const SizedBox(height: 28),
            _GeneratedArtwork(result: result),
          ],
          if (result != null && result.slides.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text(
              result.isPartial ? 'Accepted slides' : 'Generated slides',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _SlideGallery(
              configurations: context.read<DeckController>().slides.value,
            ),
          ],
          if (_planningTraces.isNotEmpty) ...[
            const SizedBox(height: 24),
            _TraceView(label: 'Story trace', traces: _planningTraces),
          ],
          if (_compositionTraces.isNotEmpty)
            _TraceView(label: 'Build trace', traces: _compositionTraces),
        ],
      ),
    );
  }
}

class _SelectionSummary extends StatelessWidget {
  const _SelectionSummary({required this.preset});

  final _GenerationPreset preset;

  @override
  Widget build(BuildContext context) {
    final request = preset.request;
    final themes = PresentationThemeCatalog.withDefaults();
    final theme = request.themeId == null
        ? null
        : themes.current(request.themeId!);
    final imageStyles = PresentationImageStyleCatalog.withDefaults();
    final imageStyle = request.imageStyleId == null
        ? null
        : imageStyles.current(request.imageStyleId!);
    final palette = theme?.recipe.palette;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Text(preset.topic, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(request.userIntent),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SelectionPill('${request.slideCount} slides'),
                if (request.audience case final audience?)
                  _SelectionPill(audience),
                if (request.approach case final approach?)
                  _SelectionPill(approach),
                if (theme != null) _SelectionPill(theme.title),
                if (imageStyle != null)
                  _SelectionPill('${imageStyle.title} artwork'),
                for (final emphasis in request.emphasis)
                  _SelectionPill(emphasis),
              ],
            ),
            if (theme != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final color in [
                    palette!.background,
                    palette.surface,
                    palette.surfaceAlt,
                    palette.heading,
                    palette.accent,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _ColorSwatch(color),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${request.headlineFont ?? theme.recipe.headlineFamily} + '
                      '${request.bodyFont ?? theme.recipe.bodyFamily}',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SelectionPill extends StatelessWidget {
  const _SelectionPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const .symmetric(vertical: 6, horizontal: 10),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    ),
  );
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch(this.hex);

  final String hex;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: hex,
    child: Container(
      decoration: BoxDecoration(
        color: _parseColor(hex),
        border: .all(color: Theme.of(context).colorScheme.outlineVariant),
        shape: .circle,
      ),
      width: 24,
      height: 24,
    ),
  );
}

class _StoryBeatReview extends StatelessWidget {
  const _StoryBeatReview({required this.plan});

  final DeckPlanType plan;

  @override
  Widget build(BuildContext context) {
    final slidesByKey = {for (final slide in plan.slides) slide.key: slide};

    return Column(
      crossAxisAlignment: .start,
      children: [
        Text('Story beats', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(plan.story),
        const SizedBox(height: 14),
        for (final (sectionIndex, section) in plan.sections.indexed)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    'Act ${sectionIndex + 1} · ${section.title}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(section.purpose),
                  const SizedBox(height: 12),
                  for (final (beatIndex, key) in section.slideKeys.indexed)
                    if (slidesByKey[key] case final slide?)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: .start,
                          children: [
                            SizedBox(
                              width: 34,
                              child: Text('${beatIndex + 1}.'),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: .start,
                                children: [
                                  Text(
                                    slide.title,
                                    style: const TextStyle(fontWeight: .w600),
                                  ),
                                  Text(slide.assertion),
                                  Text(
                                    '${slide.narrativeRole} · ${slide.composition}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  Text(
                    'Transition: ${section.transition}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TimingSummary extends StatelessWidget {
  const _TimingSummary({
    required this.planning,
    required this.composition,
    required this.result,
    required this.planningTraces,
    required this.compositionTraces,
  });

  final Duration? planning;
  final Duration? composition;
  final DeckGenerationResult? result;
  final List<GenerationTraceEvent> planningTraces;
  final List<GenerationTraceEvent> compositionTraces;

  @override
  Widget build(BuildContext context) {
    final models = {
      for (final trace in [...planningTraces, ...compositionTraces])
        if (trace.kind == .request && trace.model != null) trace.model!,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (planning != null)
          _SelectionPill('Story ${_formatDuration(planning!)}'),
        if (composition != null)
          _SelectionPill('Build ${_formatDuration(composition!)}'),
        if (planning != null && composition != null)
          _SelectionPill('Total ${_formatDuration(planning! + composition!)}'),
        if (result != null)
          _SelectionPill(
            '${result!.generatedImageCount}/${result!.generatedImages.length} images',
          ),
        for (final model in models)
          _SelectionPill(model.replaceFirst('models/', '')),
      ],
    );
  }
}

class _GeneratedArtwork extends StatelessWidget {
  const _GeneratedArtwork({required this.result});

  final DeckGenerationResult result;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    spacing: 12,
    children: [
      Text('Generated artwork', style: Theme.of(context).textTheme.titleLarge),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final (index, asset) in result.generatedImages.indexed)
            SizedBox(
              width: 240,
              child: Card(
                clipBehavior: .antiAlias,
                child: asset.bytes == null
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(asset.error ?? 'Image generation failed.'),
                      )
                    : Image.memory(
                        asset.bytes!,
                        semanticLabel: 'Generated artwork ${index + 1}',
                        height: 160,
                        fit: .cover,
                      ),
              ),
            ),
        ],
      ),
    ],
  );
}

class _TraceView extends StatelessWidget {
  const _TraceView({required this.label, required this.traces});

  final String label;
  final List<GenerationTraceEvent> traces;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: Text('$label (${traces.length} events)'),
    children: [
      SelectableText(
        const JsonEncoder.withIndent(
          ' ',
        ).convert(traces.map((event) => event.toJson()).toList()),
      ),
    ],
  );
}

class _SlideGallery extends StatelessWidget {
  const _SlideGallery({required this.configurations});

  final List<SlideConfiguration> configurations;

  @override
  Widget build(BuildContext context) => GridView.builder(
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 520,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 16 / 9,
    ),
    itemBuilder: (context, index) => ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SlideRenderView(configurations[index]),
    ),
    itemCount: configurations.length,
  );
}

final class _GenerationPreset {
  final String label;

  final String topic;
  final DeckGenerationRequest request;
  const _GenerationPreset({
    required this.label,
    required this.topic,
    required this.request,
  });
}

const _presets = [
  _GenerationPreset(
    label: 'SuperDeck booth story',
    topic: 'Build a polished deck from one idea',
    request: DeckGenerationRequest(
      userIntent:
          'Show how SuperDeck turns a rough presentation idea into a polished, '
          'coherent deck. Build a confident live-demo story from the blank-page '
          'problem through guided choices, story planning, generated visuals, '
          'and a presentation-ready result.',
      slideCount: 10,
      audience: 'Conference booth visitors and product builders',
      approach: 'Fast visual product story with a clear reveal',
      emphasis: [
        'GenUI-guided choices',
        'story beats before slide writing',
        'visible generated artwork and final quality',
      ],
      themeId: 'bold-product',
      designDirection: 'Bold, modern, energetic, and product-forward',
      headlineFont: 'Montserrat',
      bodyFont: 'DM Sans',
      imageStyleId: 'gradient',
      imageStyleVersion: 1,
      maxGeneratedImages: 3,
    ),
  ),
  _GenerationPreset(
    label: 'Editorial strategy',
    topic: 'Move from incidents to reliability engineering',
    request: DeckGenerationRequest(
      userIntent:
          'Move from reactive incident response to reliability engineering. '
          'Build a clear story from operational pain to a practical first 30 days.',
      slideCount: 10,
      audience: 'Senior product and engineering leaders',
      approach: 'Confident editorial narrative',
      emphasis: [
        'one clear assertion per slide',
        'purposeful pacing across three acts',
        'credible operational evidence',
      ],
      themeId: 'editorial-midnight',
      designDirection: 'Dark, restrained, and cinematic',
      headlineFont: 'Playfair Display',
      bodyFont: 'Inter',
      imageStyleId: 'minimalist',
      imageStyleVersion: 1,
      maxGeneratedImages: 3,
    ),
  ),
  _GenerationPreset(
    label: 'Decision deck',
    topic: 'Choose an analytics delivery strategy',
    request: DeckGenerationRequest(
      userIntent:
          'Compare build, buy, and partner approaches for analytics. Include '
          'a concise comparison table and a decision-ready recommendation.',
      slideCount: 15,
      audience: 'Product and engineering decision makers',
      approach: 'Evidence-led decision deck',
      emphasis: [
        'readable tables and metrics',
        'clear trade-offs',
        'decision-ready recommendation',
      ],
      themeId: 'technical-paper',
      designDirection: 'Light, precise, and information-rich',
      headlineFont: 'Space Grotesk',
      bodyFont: 'Open Sans',
      imageStyleId: 'minimalist',
      imageStyleVersion: 1,
      maxGeneratedImages: 2,
    ),
  ),
];

Color _parseColor(String hex) {
  final value = hex.replaceFirst('#', '');

  return Color(int.parse('FF$value', radix: 16));
}

String _formatDuration(Duration duration) =>
    '${(duration.inMilliseconds / 1000).toStringAsFixed(2)}s';
