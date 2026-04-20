import 'dart:async';

import 'package:superdeck_core/superdeck_core.dart';

import '../assets/asset_generation_pipeline.dart';
import 'slide_context.dart';
import 'task.dart';

/// Task that processes slide assets through the AssetGenerationPipeline.
///
/// Generators are registered by consumers; this task has no built-in
/// generators.
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

  /// Factory constructor that creates an asset pipeline with no default generators.
  factory AssetGenerationTask.withDefaults({
    required DeckBuildStore store,
    AssetCacheStore? cacheStore,
  }) {
    return AssetGenerationTask(
      generators: const <AssetGenerator>[],
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
