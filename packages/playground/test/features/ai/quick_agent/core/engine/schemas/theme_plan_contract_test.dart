import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:playground/core/domain/design/presentation_theme_catalog.dart';
import 'package:playground/core/domain/design/presentation_typography_catalog.dart';
import 'package:playground/features/ai/quick_agent/core/engine/schemas/deck_schemas.dart';
import 'package:playground/features/ai/quick_agent/core/engine/schemas/outline_schema.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/deck_theme_resolution.dart';
import 'package:playground/features/ai/quick_agent/core/engine/services/theme_json_serializer.dart';

void main() {
  test('model draft accepts only an eligible theme ID', () {
    final schema = buildDeckPlanDraftSchema(const [
      'editorial-midnight',
      'technical-paper',
    ]);

    final eligible = schema.safeParse(_draftPlan('editorial-midnight'));
    expect(
      eligible.isOk,
      isTrue,
      reason: eligible.isFail ? eligible.getError().toMap().toString() : null,
    );
    expect(schema.safeParse(_draftPlan('bold-product')).isOk, isFalse);
  });

  test('request-bounded draft schema excludes unavailable elements', () {
    final schema = buildDeckPlanDraftSchema(
      const ['bold-product'],
      allowedCompositionIntents: const [
        'title',
        'content',
        'imageLeft',
        'imageRight',
        'imageFullBleed',
      ],
      allowedElementTypes: const ['image'],
      allowElementSources: false,
      requireImageGenerationPrompt: true,
    );
    final valid = _draftPlan('bold-product');
    final validSlide =
        Map<String, Object?>.from((valid['slides']! as List).single as Map)
          ..['composition'] = 'imageRight'
          ..['elements'] = [
            {
              'type': 'image',
              'purpose': 'Support the product reveal',
              'generationPrompt': 'Abstract presentation canvas transforming',
            },
          ];
    valid['slides'] = [validSlide];
    final unavailable = _draftPlan('bold-product');
    final unavailableSlide =
        Map<String, Object?>.from(
            (unavailable['slides']! as List).single as Map,
          )
          ..['composition'] = 'qrcode'
          ..['elements'] = [
            {
              'type': 'qrcode',
              'purpose': 'Open an invented destination',
              'source': 'https://example.com',
            },
          ];
    unavailable['slides'] = [unavailableSlide];

    final parsedValid = schema.safeParse(valid);
    expect(
      parsedValid.isOk,
      isTrue,
      reason: parsedValid.isFail
          ? parsedValid.getError().toMap().toString()
          : null,
    );
    expect(schema.safeParse(unavailable).isOk, isFalse);
  });

  test('canonical plan requires application-owned version and density', () {
    expect(
      deckPlanSchema.safeParse(_draftPlan('editorial-midnight')).isOk,
      isFalse,
    );
    final canonical = _draftPlan('editorial-midnight');
    canonical['theme'] = {
      'id': 'editorial-midnight',
      'version': 1,
      'density': 'spacious',
    };
    canonical['slides'] = [
      for (final rawSlide in canonical['slides']! as List)
        {
          ...Map<String, Object?>.from(rawSlide as Map),
          'purpose': 'Frame the operating problem.',
          'contentBrief': 'Open with the core operating tension.',
          'continuity': 'Establish the premise for the deck.',
          'treatment': 'hero',
          'density': 'spacious',
        },
    ];
    expect(deckPlanSchema.safeParse(canonical).isOk, isTrue);
  });

  test('replays a retained versioned theme artifact exactly', () async {
    final artifact =
        jsonDecode(
              await File(
                'test/fixtures/ai_generation/theme_artifact_v1.json',
              ).readAsString(),
            )
            as Map<String, Object?>;
    final themeJson = Map<String, Object?>.from(artifact['theme']! as Map);
    final expected = Map<String, Object?>.from(artifact['expected']! as Map);
    final reference = DeckThemeReferenceType.parse(themeJson);
    final resolved = resolveDeckThemeReference(
      reference,
      themeCatalog: PresentationThemeCatalog.withDefaults(),
      typographyCatalog: PresentationTypographyCatalog.withDefaults(),
    );

    expect(serializeDeckThemeReference(reference), themeJson);
    expect(resolved.descriptor.title, expected['title']);
    expect(resolved.headlineFamily, expected['headlineFamily']);
    expect(resolved.bodyFamily, expected['bodyFamily']);
    expect(resolved.palette.background, expected['background']);
  });
}

Map<String, Object?> _draftPlan(String themeId) => {
  'topic': 'Reliable systems',
  'story': 'Move from uncertainty to a reliable operating rhythm.',
  'theme': {'id': themeId},
  'sections': [
    {
      'key': 'main',
      'title': 'Main story',
      'purpose': 'Advance the narrative.',
      'transition': 'Close with a practical action.',
      'slideKeys': ['opening'],
    },
  ],
  'slides': [
    {
      'key': 'opening',
      'title': 'Reliability starts here',
      'sectionKey': 'main',
      'assertion': 'A reliable system begins with shared priorities.',
      'contentUnits': ['One concrete supporting point'],
      'narrativeRole': 'opening',
      'composition': 'title',
      'elements': <Object?>[],
    },
  ],
};
