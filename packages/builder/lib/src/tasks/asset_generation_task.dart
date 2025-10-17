import 'dart:async';

import 'package:superdeck_core/superdeck_core.dart';

import '../assets/asset_generation_pipeline.dart';
import '../assets/asset_generator.dart';
import '../assets/mermaid_generator.dart';
import 'slide_context.dart';
import 'task.dart';

/// Task that processes slide assets through the AssetGenerationPipeline.
///
/// This task coordinates all build-time asset generation (Mermaid, images, etc.)
/// through a unified AssetGenerationPipeline.
final class AssetGenerationTask extends Task {
  final AssetGenerationPipeline _pipeline;

  AssetGenerationTask({
    required List<AssetGenerator> generators,
    required DeckRepository store,
    Map<String, dynamic> configuration = const {},
  }) : _pipeline = AssetGenerationPipeline(
         generators: generators,
         store: store,
       ),
       super('asset_generation', configuration: configuration);

  /// Factory constructor that creates a default asset pipeline with standard generators.
  factory AssetGenerationTask.withDefaults({
    required DeckRepository store,
    Map<String, dynamic>? browserLaunchOptions,
    Map<String, dynamic> configuration = const {},
  }) {
    final generators = <AssetGenerator>[
      MermaidGenerator(launchOptions: browserLaunchOptions),
    ];

    return AssetGenerationTask(
      generators: generators,
      store: store,
      configuration: configuration,
    );
  }

  @override
  Future<void> run(SlideContext context) async {
    logger.info('Generating assets for slide ${context.slideIndex}');

    try {
      final result = await _pipeline.processSlideContent(
        context.slide.content,
        context.slideIndex,
      );

      // Update the slide content with asset references
      context.slide = context.slide.copyWith(content: result.updatedContent);

      logger.info(
        'Asset generation completed for slide ${context.slideIndex}. '
        'Generated ${result.generatedAssets.length} assets.',
      );
    } catch (e) {
      logger.severe(
        'Asset generation failed for slide ${context.slideIndex}: $e',
      );
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    await _pipeline.dispose();
  }
}
