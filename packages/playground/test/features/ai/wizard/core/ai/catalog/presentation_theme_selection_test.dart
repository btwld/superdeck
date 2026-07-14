import 'package:flutter_test/flutter_test.dart';
import 'package:playground/core/domain/design/presentation_theme_catalog.dart';
import 'package:playground/features/ai/wizard/core/ai/catalog/ask_user_style.dart';
import 'package:playground/features/ai/wizard/core/ai/catalog/summary_card.dart';
import 'package:playground/features/ai/wizard/chat/chat_conversation_profile.dart';
import 'package:playground/features/ai/wizard/core/ai/schemas/wizard_context_keys.dart';
import 'package:playground/features/ai/wizard/core/ai/services/genui_conversation_session.dart';

void main() {
  group('Wizard presentation theme selection', () {
    test('accepts only registered theme IDs', () {
      final themeCatalog = PresentationThemeCatalog.withDefaults();
      final data = parseAskUserStyle({
        'question': 'Choose a theme',
        'themeIds': featuredPresentationThemeIds,
        'action': {'name': 'submit_answer', 'context': <Object?>[]},
      }, themeCatalog: themeCatalog);

      expect(data.themeIds, featuredPresentationThemeIds);
      expect(
        () => parseAskUserStyle({
          'question': 'Choose a theme',
          'themeIds': ['invented-theme'],
          'action': {'name': 'submit_answer', 'context': <Object?>[]},
        }, themeCatalog: themeCatalog),
        throwsA(anything),
      );
      expect(
        () => parseAskUserStyle({
          'question': 'Choose a theme',
          'themeIds': ['editorial-midnight'],
          'action': {'name': 'submit_answer', 'context': <Object?>[]},
        }, themeCatalog: themeCatalog),
        throwsA(anything),
      );
    });

    test('maps a card selection to an exact theme without token overrides', () {
      final context = buildThemeSelectionContext('bold-product');

      expect(context[WizardContextKeys.themeId], 'bold-product');
      expect(context[WizardContextKeys.title], 'Bold Product');
      expect(context[WizardContextKeys.description], isNotEmpty);
      expect(context, isNot(contains(WizardContextKeys.colors)));
      expect(context, isNot(contains(WizardContextKeys.headlineFont)));
      expect(context, isNot(contains(WizardContextKeys.bodyFont)));
    });

    test('summary restores the stable theme ID only', () {
      final item = SummaryItemType.parse({
        'kind': 'theme',
        'label': 'Style',
        'themeId': 'technical-paper',
      });

      expect(item.shapeValidationError, isNull);
      final context = extractWizardContextFromSummaryItems([item]);

      expect(context.themeId, 'technical-paper');
      expect(context.style, isNull);
      expect(context.colors, isNull);
      expect(context.headlineFont, isNull);
      expect(context.bodyFont, isNull);
    });

    test('Wizard prompt exposes compact catalog metadata without recipes', () {
      final prompt = buildWizardThemeCatalogPrompt(
        PresentationThemeCatalog.withDefaults(),
      );

      for (final themeId in defaultPresentationThemeIds) {
        expect(prompt, contains(themeId));
      }
      expect(prompt, contains('description'));
      expect(prompt, isNot(contains('headlineFamily')));
      expect(prompt, isNot(contains('bodyFamily')));
      expect(prompt, isNot(matches(RegExp(r'#[0-9A-Fa-f]{6}'))));
    });

    test(
      'one injected catalog owns the Wizard prompt and component schemas',
      () {
        final defaults = PresentationThemeCatalog.withDefaults().currentThemes;
        final customIds = [
          'custom-editorial',
          'custom-technical',
          'custom-bold',
        ];
        final catalog = PresentationThemeCatalog([
          for (final (index, id) in customIds.indexed)
            _themeWithId(defaults[index], id),
        ]);

        final profile = chatConversationProfile(themeCatalog: catalog);
        final items = {
          for (final item in profile.catalog.items) item.name: item,
        };

        expect(profile.themeCatalog, same(catalog));
        expect(
          _enumAt(items['AskUserStyle']!.dataSchema.value, [
            'properties',
            'themeIds',
            'items',
          ]),
          customIds,
        );
        expect(
          _enumAt(items['SummaryCard']!.dataSchema.value, [
            'properties',
            'items',
            'items',
            'properties',
            'themeId',
          ]),
          customIds,
        );
        for (final componentName in ['AskUserStyle', 'SummaryCard']) {
          final examples = items[componentName]!.exampleData.map(
            (build) => build(),
          );
          expect(examples, everyElement(isNot(contains('editorial-midnight'))));
          expect(examples.join(), contains(customIds.first));
        }
        final prompt = buildWizardThemeCatalogPrompt(profile.themeCatalog);
        for (final id in customIds) {
          expect(prompt, contains(id));
        }
        expect(
          parseAskUserStyle({
            'question': 'Choose a theme',
            'themeIds': customIds,
            'action': {'name': 'submit_answer', 'context': <Object?>[]},
          }, themeCatalog: catalog).themeIds,
          customIds,
        );
        expect(
          buildThemeSelectionContext(
            customIds.first,
            themeCatalog: catalog,
          )[WizardContextKeys.themeId],
          customIds.first,
        );
        expect(
          parseSummaryCard({
            'title': 'Summary',
            'items': [
              {'kind': 'theme', 'label': 'Style', 'themeId': customIds.first},
            ],
            'generateSlidesAction': {
              'name': 'generate_slides',
              'context': <Object?>[],
            },
          }, themeCatalog: catalog).items.single.themeId,
          customIds.first,
        );
      },
    );
  });
}

PresentationThemeDescriptor _themeWithId(
  PresentationThemeDescriptor source,
  String id,
) {
  return PresentationThemeDescriptor(
    id: id,
    version: source.version,
    title: source.title,
    description: source.description,
    directionTags: source.directionTags,
    moodTags: source.moodTags,
    audienceTags: source.audienceTags,
    contentTags: source.contentTags,
    brightness: source.brightness,
    supportedDensities: source.supportedDensities,
    recipe: source.recipe,
  );
}

List<Object?> _enumAt(Map<String, Object?> schema, List<String> path) {
  Object? current = schema;
  for (final segment in path) {
    current = (current as Map)[segment];
  }
  return ((current as Map)['enum'] as List).cast<Object?>();
}
