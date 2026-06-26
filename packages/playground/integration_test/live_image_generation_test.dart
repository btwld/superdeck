@Tags(['live'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:playground/features/ai/core/ai/prompts/examples_loader.dart';
import 'package:playground/features/ai/core/ai/prompts/prompt_registry.dart';
import 'package:playground/features/ai/core/ai/services/deck_generator_service.dart';
import 'package:playground/features/ai/core/ai/services/image_generator_service.dart';
import 'package:playground/features/ai/core/constants/gemini_image_options.dart';
import 'package:playground/utils/memory_asset_cache_store.dart';
import 'package:superdeck_builder/superdeck_builder.dart';

/// Live end-to-end checks against the real Gemini API. Unlike `flutter test`,
/// the integration binding permits real network calls.
///
/// Run:
///   cd packages/playground
///   fvm flutter test integration_test/live_image_generation_test.dart -d macos
///
/// Skips automatically unless GOOGLE_AI_API_KEY is present in the environment.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final apiKey = Platform.environment['GOOGLE_AI_API_KEY'];
  final bool skip = apiKey == null || apiKey.isEmpty;

  // Quota / rate-limit / overload errors are account-side, not code failures —
  // treat them as inconclusive (skip) rather than red so this stays a useful
  // diagnostic with a free-tier key.
  bool isQuota(String? error) {
    if (error == null) return false;
    final s = error.toLowerCase();
    return s.contains('quota') ||
        s.contains('rate limit') ||
        s.contains('exceeded') ||
        s.contains('overloaded') ||
        s.contains('resource_exhausted') ||
        s.contains('toomanyrequests') ||
        s.contains('too many') ||
        s.contains('429');
  }

  setUpAll(() async {
    if (skip) return;
    await PromptRegistry.instance.load();
    await ExamplesLoader.instance.load();
  });

  testWidgets(
    'image model returns real PNG bytes',
    (tester) async {
      final service = ImageGeneratorService(
        apiKey: apiKey!,
        aspectRatio: GeminiImageAspectRatio.portrait3x4,
      );
      final ImageGenerationResult result;
      try {
        result = await service.generateImage(
          ImageGeneratorService.buildPrompt('a steaming cup of coffee'),
        );
      } catch (e) {
        if (isQuota(e.toString())) {
          markTestSkipped('Gemini quota/rate limited: $e');
          return;
        }
        rethrow;
      } finally {
        service.dispose();
      }

      // ignore: avoid_print
      print(
        'IMAGE: success=${result.success} bytes=${result.bytes?.length} '
        'error=${result.error}',
      );
      if (!result.success && isQuota(result.error)) {
        markTestSkipped('Gemini quota/rate limited: ${result.error}');
        return;
      }
      expect(result.success, isTrue, reason: result.error);
      expect(result.bytes, isNotNull);
      expect(result.bytes!.length, greaterThan(100));
    },
    timeout: const Timeout(Duration(minutes: 3)),
    skip: skip,
  );

  testWidgets(
    'full pipeline generates slides (+ images) and they cache + serialize',
    (tester) async {
      final service = DeckGeneratorService(apiKey: apiKey!);
      final result = await service.generate(
        'A 4-slide visual introduction to the solar system, with an '
        'illustration on the key slides. Professional tone.',
        imageStyleId: 'watercolor',
      );

      // ignore: avoid_print
      print(
        'DECK: success=${result.success} slides=${result.slideCount} '
        'images=${result.images.length} style=${result.style != null} '
        'error=${result.error}',
      );
      if (!result.success && isQuota(result.error)) {
        markTestSkipped('Gemini quota/rate limited: ${result.error}');
        return;
      }
      expect(result.success, isTrue, reason: result.error);
      expect(result.slides, isNotEmpty);

      // Cache any generated images and serialize the deck the way AiStore does.
      final store = MemoryAssetCacheStore();
      for (final entry in result.images.entries) {
        await store.write(entry.key, entry.value);
      }
      final markdown = const SlideSerializer().serialize(result.slides);
      // ignore: avoid_print
      print(
        'MARKDOWN (${markdown.length} chars):\n'
        '${markdown.substring(0, markdown.length.clamp(0, 1500))}',
      );
      expect(markdown.trim(), isNotEmpty);

      // Every cached image key should resolve back to a data: URI (what the
      // renderer uses to display it).
      for (final key in result.images.keys) {
        final uri = await store.resolve(key);
        expect(uri?.scheme, 'data', reason: 'image $key should resolve');
        // The serialized markdown should reference the bare key (clean editor).
        expect(
          markdown.contains(key),
          isTrue,
          reason: 'markdown should reference $key',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 6)),
    skip: skip,
  );
}
