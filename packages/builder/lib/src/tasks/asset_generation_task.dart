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
    required DeckBuildStore store,
    AssetCacheStore? cacheStore,
  }) : _pipeline = AssetGenerationPipeline(
         generators: generators,
         store: store,
         cacheStore: cacheStore,
       ),
       super('asset_generation');

  /// Factory constructor that creates a default asset pipeline with standard generators.
  factory AssetGenerationTask.withDefaults({
    required DeckBuildStore store,
    Map<String, Object?>? browserLaunchOptions,
    AssetCacheStore? cacheStore,
  }) {
    final generators = <AssetGenerator>[
      MermaidGenerator(launchOptions: browserLaunchOptions),
    ];

    return AssetGenerationTask(
      generators: generators,
      store: store,
      cacheStore: cacheStore,
    );
  }

  @override
  Future<void> run(SlideContext context) async {
    final result = await _pipeline.processSlideContent(
      context.slide.content,
      context.slideIndex,
    );

    context.updateSlide(context.slide.copyWith(content: result.updatedContent));
  }

  @override
  Future<void> dispose() async {
    await _pipeline.dispose();
  }
}
