part of 'deck_generator_service.dart';

typedef ImageGenerationProgressCallback =
    void Function(int completed, int total);

/// Rewritten composition plan and ordered image outcomes for one run.
final class DeckImageGenerationResult {
  final DeckPlanType plan;

  final List<GeneratedImageAsset> assets;
  const DeckImageGenerationResult({required this.plan, required this.assets});
}

final class _PlannedImage {
  final int slideIndex;

  final int elementIndex;
  final String subject;
  final String assetKey;
  final GeneratedImageAspectRatio aspectRatio;
  final String? backgroundColor;
  const _PlannedImage({
    required this.slideIndex,
    required this.elementIndex,
    required this.subject,
    required this.assetKey,
    required this.aspectRatio,
    required this.backgroundColor,
  });
}

Future<DeckImageGenerationResult> _runImagePhase(
  DeckGeneratorService owner, {
  required DeckPlanType plan,
  required DeckGenerationRequest request,
  required GenerationProgressCallback? onProgress,
  required GenerationTraceEmitter trace,
  required bool Function() isCancelled,
}) async {
  final style = request.resolveImageStyle(owner.imageStyleCatalog);
  if (style == null) {
    return DeckImageGenerationResult(plan: plan, assets: const []);
  }

  debugLog.section('Phase 2: Generate Artwork');
  trace.emit(kind: .phaseStarted, phase: .image);
  final resolvedTheme = resolveDeckThemeReference(
    plan.theme,
    themeCatalog: owner.themeCatalog,
    typographyCatalog: owner.typographyCatalog,
  );
  final timer = Stopwatch()..start();
  final result = await generateImagesForPlan(
    plan: plan,
    imageStyle: style,
    generator: owner.imageGenerator ?? const UnavailableImageGenerator(),
    runId: owner._assetRunIdFactory(),
    backgroundColor: resolvedTheme.palette.background,
    backgroundColorsByTreatment: {
      for (final treatment
          in plan.slides.map((slide) => slide.treatment).toSet())
        treatment: _imageBackgroundForTreatment(resolvedTheme, treatment),
    },
    onProgress: (completed, total) => onProgress?.call(
      GenerationProgress(
        .generatingImages,
        completedItems: completed,
        totalItems: total,
      ),
    ),
    isCancelled: isCancelled,
  );
  timer.stop();
  if (!isCancelled()) {
    final successful = result.assets
        .where((asset) => asset.bytes != null)
        .length;
    debugLog.log(
      'DECK_GEN',
      'Artwork COMPLETE in '
          '${timer.elapsedMilliseconds}ms - '
          '$successful of ${result.assets.length} ready',
    );
    trace.emit(kind: .phaseDone, phase: .image);
  }

  return result;
}

/// Generates planned artwork with bounded concurrency and returns a plan that
/// references only successful assets. Failed visuals fall back to text layouts.
Future<DeckImageGenerationResult> generateImagesForPlan({
  required DeckPlanType plan,
  required PresentationImageStyleDescriptor imageStyle,
  required ImageGenerator generator,
  required String runId,
  String? backgroundColor,
  Map<String, String> backgroundColorsByTreatment = const {},
  ImageGenerationProgressCallback? onProgress,
  bool Function()? isCancelled,
  int maxConcurrency = 4,
}) async {
  if (maxConcurrency < 1) {
    throw ArgumentError.value(
      maxConcurrency,
      'maxConcurrency',
      'Must be positive.',
    );
  }
  final planned = _plannedImages(
    plan,
    runId,
    backgroundColor: backgroundColor,
    backgroundColorsByTreatment: backgroundColorsByTreatment,
  );
  if (planned.isEmpty) {
    onProgress?.call(0, 0);

    return DeckImageGenerationResult(plan: plan, assets: const []);
  }

  var nextIndex = 0;
  var completed = 0;
  final results = List<GeneratedImageAsset?>.filled(planned.length, null);
  onProgress?.call(0, planned.length);

  Future<void> worker() async {
    while (!(isCancelled?.call() ?? false)) {
      final workIndex = nextIndex++;
      if (workIndex >= planned.length) return;

      final image = planned[workIndex];
      final result = await generateImageSafely(
        generator,
        ImageGenerationRequest(
          prompt: buildPresentationImagePrompt(
            imageStyle.buildPrompt(image.subject),
            backgroundColor: image.backgroundColor,
          ),
          aspectRatio: image.aspectRatio,
        ),
      );
      results[workIndex] = switch (result) {
        ImageGenerationSuccess(:final bytes) => GeneratedImageAsset.success(
          assetKey: image.assetKey,
          bytes: bytes,
        ),
        ImageGenerationFailure(:final message) => GeneratedImageAsset.failure(
          assetKey: image.assetKey,
          error: message,
        ),
      };
      completed++;
      onProgress?.call(completed, planned.length);
    }
  }

  final workerCount = planned.length < maxConcurrency
      ? planned.length
      : maxConcurrency;
  await Future.wait(List.generate(workerCount, (_) => worker()));
  final assets = results.nonNulls.toList(growable: false);
  if (isCancelled?.call() ?? false) {
    return DeckImageGenerationResult(plan: plan, assets: assets);
  }

  return DeckImageGenerationResult(
    plan: _rewriteGeneratedImageSources(plan, planned, assets),
    assets: assets,
  );
}

List<_PlannedImage> _plannedImages(
  DeckPlanType plan,
  String runId, {
  required String? backgroundColor,
  required Map<String, String> backgroundColorsByTreatment,
}) {
  final planned = <_PlannedImage>[];
  for (final (slideIndex, slide) in plan.slides.indexed) {
    for (final (elementIndex, element)
        in (slide.elements ?? const <DeckPlanElementType>[]).indexed) {
      final subject = element.generationPrompt?.trim();
      if (element.type != 'image' || subject == null || subject.isEmpty) {
        continue;
      }
      planned.add(
        _PlannedImage(
          slideIndex: slideIndex,
          elementIndex: elementIndex,
          subject: subject,
          assetKey: buildGeneratedAssetKey(
            runId: runId,
            slideIndex: slideIndex,
            slideKey: slide.key,
          ),
          aspectRatio: slide.composition == 'imageFullBleed'
              ? .landscape16x9
              : .slide3x4,
          backgroundColor:
              backgroundColorsByTreatment[slide.treatment] ?? backgroundColor,
        ),
      );
    }
  }

  return planned;
}

String _imageBackgroundForTreatment(
  ResolvedPresentationTheme theme,
  String treatment,
) {
  final role =
      theme.descriptor.recipe.runtime.treatments.byName[treatment]?.background;

  return switch (role) {
    .surface => theme.palette.surface,
    .surfaceAlt => theme.palette.surfaceAlt,
    .accent => theme.palette.accent,
    .background || null => theme.palette.background,
  };
}

DeckPlanType _rewriteGeneratedImageSources(
  DeckPlanType plan,
  List<_PlannedImage> planned,
  List<GeneratedImageAsset> assets,
) {
  final rewritten = jsonDecode(jsonEncode(plan)) as Map<String, dynamic>;
  final slides = rewritten['slides']! as List;

  for (final (index, image) in planned.indexed.toList().reversed) {
    final slide = slides[image.slideIndex] as Map;
    final elements = slide['elements']! as List;
    final asset = assets[index];
    if (asset.bytes case final bytes? when bytes.isNotEmpty) {
      final element = elements[image.elementIndex] as Map;
      element['source'] = image.assetKey;
      element.remove('generationPrompt');
      continue;
    }

    elements.removeAt(image.elementIndex);
    if (slide['composition'] case final String composition
        when composition == 'imageLeft' ||
            composition == 'imageRight' ||
            composition == 'imageFullBleed') {
      slide['composition'] = 'content';
      slide['treatment'] = 'content';
    }
  }

  return DeckPlanType.parse(rewritten);
}

String buildGeneratedAssetKey({
  required String runId,
  required int slideIndex,
  required String slideKey,
}) {
  final safeRun = _safeAssetSlug(runId, fallback: 'run', maxLength: 24);
  final safeSlide = _safeAssetSlug(slideKey, fallback: 'slide', maxLength: 42);
  final number = (slideIndex + 1).toString().padLeft(2, '0');

  return 'wizard-$safeRun-slide-$number-$safeSlide.png';
}

String _safeAssetSlug(
  String value, {
  required String fallback,
  required int maxLength,
}) {
  var slug = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.isEmpty) slug = fallback;
  if (slug.length > maxLength) {
    slug = slug.substring(0, maxLength).replaceFirst(RegExp(r'-+$'), '');
  }

  return slug;
}
