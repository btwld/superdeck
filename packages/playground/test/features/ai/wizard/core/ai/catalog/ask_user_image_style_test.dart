import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui/test/validation.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:playground/core/domain/generated_image_asset.dart';
import 'package:playground/features/ai/image_generation/image_generator.dart';
import 'package:playground/features/ai/wizard/core/ai/catalog/catalog.dart';
import 'package:playground/features/ai/wizard/core/ai/catalog/ask_user_question_cards.dart';
import 'package:playground/features/ai/wizard/core/ai/prompts/image_style_prompts.dart';
import 'package:playground/features/ai/wizard/core/ui/ui.dart';
import 'package:provider/provider.dart';

final class _ControlledImageGenerator implements ImageGenerator {
  final List<ImageGenerationRequest> requests = [];
  final List<Completer<ImageGenerationResult>> _responses = [];

  @override
  Future<ImageGenerationResult> generate(ImageGenerationRequest request) {
    requests.add(request);
    final response = Completer<ImageGenerationResult>();
    _responses.add(response);
    return response.future;
  }

  void completeNext(ImageGenerationResult result) {
    _responses.firstWhere((response) => !response.isCompleted).complete(result);
  }
}

final _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=',
);

void main() {
  group('AskUserImageStyle schema', () {
    test('accepts exactly three distinct curated styles', () {
      final parsed = AskUserImageStyleType.parse({
        'question': 'Choose artwork',
        'subject': 'a satellite above Earth',
        'imageStyles': ['watercolor', 'minimalist', 'geometric'],
        'action': {'name': 'submit_answer', 'context': []},
      });

      expect(parsed.subject, 'a satellite above Earth');
      expect(parsed.imageStyles, [
        ImageStyle.watercolor,
        ImageStyle.minimalist,
        ImageStyle.geometric,
      ]);
    });

    test('rejects fewer than three styles and duplicate styles', () {
      Map<String, Object> data(List<String> styles) => {
        'question': 'Choose artwork',
        'subject': 'a satellite above Earth',
        'imageStyles': styles,
        'action': {'name': 'submit_answer', 'context': <Object>[]},
      };

      expect(
        () => AskUserImageStyleType.parse(data(['watercolor', 'minimalist'])),
        throwsA(anything),
      );
      expect(
        () => AskUserImageStyleType.parse(
          data(['watercolor', 'watercolor', 'minimalist']),
        ),
        throwsA(anything),
      );
    });

    test('catalog examples validate', () async {
      final errors = await validateCatalogItemExamples(
        askUserImageStyle,
        chatCatalog,
      );

      expect(errors, isEmpty);
    });
  });

  testWidgets('broken preview stays selectable and exposes manual retry', (
    tester,
  ) async {
    var selected = false;
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: HeroTheme(
          data: HeroThemeData.light(),
          child: Scaffold(
            body: ImageStyleOptionCard(
              style: ImageStyle.minimalist,
              hasFailed: true,
              selected: false,
              onTap: () => selected = true,
              onRetry: () => retried = true,
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(retried, isTrue);

    await tester.tap(find.text('Minimalist'));
    await tester.pump();
    expect(selected, isTrue);
  });

  testWidgets(
    'previews share a subject and retry only after a failed card requests it',
    (tester) async {
      final generator = _ControlledImageGenerator();
      final dataModel = InMemoryDataModel();
      addTearDown(dataModel.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: HeroTheme(
            data: HeroThemeData.light(),
            child: Provider<ImageGenerator>.value(
              value: generator,
              child: Scaffold(
                body: Builder(
                  builder: (context) => askUserImageStyle.widgetBuilder(
                    CatalogItemContext(
                      data: {
                        'question': 'Choose artwork',
                        'subject': 'a satellite above Earth',
                        'imageStyles': [
                          'watercolor',
                          'minimalist',
                          'geometric',
                        ],
                        'action': {
                          'name': 'submit_answer',
                          'context': <Object>[],
                        },
                      },
                      id: 'root',
                      type: 'AskUserImageStyle',
                      buildChild: (id, [dataContext]) => const SizedBox(),
                      dispatchEvent: (_) {},
                      buildContext: context,
                      dataContext: DataContext(dataModel, DataPath.root),
                      getComponent: (_) => null,
                      getCatalogItem: (_) => null,
                      surfaceId: 'test-surface',
                      reportError: (error, stackTrace) => fail('$error'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ImageStyleOptionCard), findsNWidgets(3));
      expect(find.byType(SdSpinner), findsNWidgets(3));
      expect(generator.requests, hasLength(1));

      generator.completeNext(ImageGenerationSuccess(_onePixelPng));
      await tester.pump();
      expect(generator.requests, hasLength(2));

      generator.completeNext(const ImageGenerationFailure('Provider failed'));
      await tester.pump();
      expect(generator.requests, hasLength(3));

      generator.completeNext(ImageGenerationSuccess(_onePixelPng));
      await tester.pump();

      expect(generator.requests.map((request) => request.aspectRatio).toSet(), {
        GeneratedImageAspectRatio.preview16x9,
      });
      for (final request in generator.requests) {
        expect(request.prompt, contains('satellite above Earth'));
      }
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
      expect(generator.requests, hasLength(3));

      await tester.tap(find.text('Minimalist'));
      await tester.pump();
      final selectedCard = tester
          .widgetList<ImageStyleOptionCard>(find.byType(ImageStyleOptionCard))
          .singleWhere((card) => card.style == ImageStyle.minimalist);
      expect(selectedCard.selected, isTrue);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(generator.requests, hasLength(4));
      generator.completeNext(ImageGenerationSuccess(_onePixelPng));
      await tester.pump();

      expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
    },
  );
}
