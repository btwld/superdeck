import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:remix/remix.dart';

import 'package:superdeck_genui/src/ai/catalog/ask_user_question_cards.dart';
import 'package:superdeck_genui/src/ai/catalog/catalog.dart';
import 'package:superdeck_genui/src/ai/prompts/prompt_registry.dart';
import 'package:superdeck_genui/src/ai/services/image_generator_service.dart';
import 'package:superdeck_genui/src/ui/ui.dart';

class _QueuedImageService extends ImageGeneratorService {
  _QueuedImageService(this._results) : super(apiKey: 'test');

  final List<Completer<ImageGenerationResult>> _results;
  int _index = 0;

  @override
  Future<ImageGenerationResult> generateImage(String prompt) {
    expect(
      _index,
      lessThan(_results.length),
      reason: 'Unexpected generateImage call.',
    );
    return _results[_index++].future;
  }

  @override
  void dispose() {}
}

Widget _buildCatalogItemWidget({
  required CatalogItem item,
  required Map<String, Object?> data,
  ValueChanged<UiEvent>? onEvent,
}) {
  return MaterialApp(
    builder: (context, child) {
      return createRemixScope(child: child!, accent: .iris);
    },
    home: Scaffold(
      body: SingleChildScrollView(
        child: Builder(
          builder: (context) {
            return item.widgetBuilder(
              CatalogItemContext(
                id: 'root',
                data: data,
                buildChild: (_, [_]) => const SizedBox.shrink(),
                dispatchEvent: onEvent ?? (_) {},
                buildContext: context,
                dataContext: DataContext(DataModel(), '/'),
                getComponent: (_) => null,
                surfaceId: 'test-surface',
              ),
            );
          },
        ),
      ),
    ),
  );
}

Map<String, Object?> _imageStyleData({
  required String subject,
  required List<String> imageStyles,
}) {
  return {
    'question': 'Choose style',
    'description': 'Pick one style',
    'subject': subject,
    'imageStyles': imageStyles,
    'action': {'name': 'submit_answer', 'context': []},
  };
}

Map<String, Object?> _sliderData({
  required int min,
  required int max,
  required int defaultValue,
}) {
  return {
    'question': 'How many slides?',
    'description': 'Pick a count',
    'minValue': min,
    'maxValue': max,
    'defaultValue': defaultValue,
    'unit': 'slides',
    'action': {'name': 'submit_answer', 'context': []},
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    dotenv.loadFromString(envString: 'GOOGLE_AI_API_KEY=test_api_key');
    PromptRegistry.instance.loadForTest(
      prompts: {'image_generation': 'test image prompt'},
    );
  });

  tearDownAll(() {
    resetImageGeneratorServiceFactory();
    PromptRegistry.instance.reset();
  });

  tearDown(() {
    resetImageGeneratorServiceFactory();
  });

  group('Catalog widget regressions', () {
    testWidgets(
      'AskUserImageStyle ignores stale results after subject change',
      (tester) async {
        final firstGen = [
          Completer<ImageGenerationResult>(),
          Completer<ImageGenerationResult>(),
        ];
        final secondGen = [
          Completer<ImageGenerationResult>(),
          Completer<ImageGenerationResult>(),
        ];
        final services = Queue<_QueuedImageService>.from([
          _QueuedImageService(firstGen),
          _QueuedImageService(secondGen),
        ]);

        imageGeneratorServiceFactory = ({required String apiKey}) {
          expect(services, isNotEmpty, reason: 'No fake service queued.');
          return services.removeFirst();
        };

        await tester.pumpWidget(
          _buildCatalogItemWidget(
            item: askUserImageStyle,
            data: _imageStyleData(
              subject: 'subject-a',
              imageStyles: ['watercolor', 'minimalist'],
            ),
          ),
        );
        await tester.pump();

        List<ImageStyleOptionCard> cards() => tester
            .widgetList<ImageStyleOptionCard>(find.byType(ImageStyleOptionCard))
            .toList();

        expect(cards(), hasLength(2));
        expect(cards().every((c) => c.isLoading), isTrue);

        await tester.pumpWidget(
          _buildCatalogItemWidget(
            item: askUserImageStyle,
            data: _imageStyleData(
              subject: 'subject-b',
              imageStyles: ['watercolor', 'minimalist'],
            ),
          ),
        );
        await tester.pump();
        expect(cards().every((c) => c.isLoading), isTrue);

        firstGen[0].complete(
          ImageGenerationResult.success(Uint8List.fromList([1])),
        );
        firstGen[1].complete(
          ImageGenerationResult.success(Uint8List.fromList([2])),
        );
        await tester.pump();

        final afterStale = cards();
        expect(afterStale.every((c) => c.isLoading), isTrue);
        expect(afterStale.every((c) => c.imageBytes == null), isTrue);

        secondGen[0].complete(
          ImageGenerationResult.success(Uint8List.fromList([9])),
        );
        secondGen[1].complete(
          ImageGenerationResult.success(Uint8List.fromList([8])),
        );
        await tester.pump();

        final afterFresh = cards();
        expect(afterFresh.every((c) => c.isLoading), isFalse);
        expect(afterFresh[0].imageBytes?.toList(), equals([9]));
        expect(afterFresh[1].imageBytes?.toList(), equals([8]));
      },
    );

    testWidgets(
      'AskUserImageStyle regenerates previews when style list changes',
      (tester) async {
        final firstGen = [
          Completer<ImageGenerationResult>(),
          Completer<ImageGenerationResult>(),
        ];
        final secondGen = [
          Completer<ImageGenerationResult>(),
          Completer<ImageGenerationResult>(),
        ];
        final services = Queue<_QueuedImageService>.from([
          _QueuedImageService(firstGen),
          _QueuedImageService(secondGen),
        ]);

        imageGeneratorServiceFactory = ({required String apiKey}) {
          expect(services, isNotEmpty, reason: 'No fake service queued.');
          return services.removeFirst();
        };

        await tester.pumpWidget(
          _buildCatalogItemWidget(
            item: askUserImageStyle,
            data: _imageStyleData(
              subject: 'same-subject',
              imageStyles: ['watercolor', 'minimalist'],
            ),
          ),
        );
        await tester.pump();

        firstGen[0].complete(
          ImageGenerationResult.success(Uint8List.fromList([1])),
        );
        firstGen[1].complete(
          ImageGenerationResult.success(Uint8List.fromList([2])),
        );
        await tester.pump();

        List<ImageStyleOptionCard> cards() => tester
            .widgetList<ImageStyleOptionCard>(find.byType(ImageStyleOptionCard))
            .toList();
        expect(cards().every((c) => c.isLoading), isFalse);
        expect(cards()[0].imageBytes?.toList(), equals([1]));

        await tester.pumpWidget(
          _buildCatalogItemWidget(
            item: askUserImageStyle,
            data: _imageStyleData(
              subject: 'same-subject',
              imageStyles: ['watercolor', 'gradient'],
            ),
          ),
        );
        await tester.pump();

        final duringRegeneration = cards();
        expect(duringRegeneration.every((c) => c.isLoading), isTrue);
        expect(duringRegeneration.every((c) => c.imageBytes == null), isTrue);

        secondGen[0].complete(
          ImageGenerationResult.success(Uint8List.fromList([3])),
        );
        secondGen[1].complete(
          ImageGenerationResult.success(Uint8List.fromList([4])),
        );
        await tester.pump();

        final afterRegeneration = cards();
        expect(afterRegeneration.every((c) => c.isLoading), isFalse);
        expect(afterRegeneration[0].imageBytes?.toList(), equals([3]));
        expect(afterRegeneration[1].imageBytes?.toList(), equals([4]));
      },
    );

    testWidgets('AskUserSlider clamps current value when max decreases', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildCatalogItemWidget(
          item: askUserSlider,
          data: _sliderData(min: 0, max: 10, defaultValue: 5),
        ),
      );
      await tester.pump();

      var slider = tester.widget<SdSlider>(find.byType(SdSlider));
      expect(slider.value, 5.0);

      slider.onChanged(9);
      await tester.pump();
      slider = tester.widget<SdSlider>(find.byType(SdSlider));
      expect(slider.value, 9.0);

      await tester.pumpWidget(
        _buildCatalogItemWidget(
          item: askUserSlider,
          data: _sliderData(min: 0, max: 4, defaultValue: 5),
        ),
      );
      await tester.pump();

      slider = tester.widget<SdSlider>(find.byType(SdSlider));
      expect(slider.value, 4.0);
    });

    testWidgets('AskUserSlider applies new default value on widget update', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildCatalogItemWidget(
          item: askUserSlider,
          data: _sliderData(min: 0, max: 10, defaultValue: 3),
        ),
      );
      await tester.pump();

      var slider = tester.widget<SdSlider>(find.byType(SdSlider));
      expect(slider.value, 3.0);

      slider.onChanged(8);
      await tester.pump();
      slider = tester.widget<SdSlider>(find.byType(SdSlider));
      expect(slider.value, 8.0);

      await tester.pumpWidget(
        _buildCatalogItemWidget(
          item: askUserSlider,
          data: _sliderData(min: 0, max: 10, defaultValue: 2),
        ),
      );
      await tester.pump();

      slider = tester.widget<SdSlider>(find.byType(SdSlider));
      expect(slider.value, 2.0);
    });
  });
}
