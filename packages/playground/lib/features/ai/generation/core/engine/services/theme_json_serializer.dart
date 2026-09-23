import '../schemas/deck_schemas.dart';
import '../schemas/outline_schema.dart';

/// Serializes the canonical theme reference for persisted artifacts.
Map<String, Object?> serializeDeckThemeReference(DeckThemeReference theme) {
  final result = <String, Object?>{
    'id': theme.id,
    'version': theme.version,
    'density': theme.density,
  };
  if (theme.brandOverride case final override?) {
    final overrideJson = <String, Object?>{};
    if (override.colors case final colors?) {
      overrideJson['colors'] = {
        'background': ?colors.background,
        'surface': ?colors.surface,
        'surfaceAlt': ?colors.surfaceAlt,
        'heading': ?colors.heading,
        'body': ?colors.body,
        'accent': ?colors.accent,
        'accentContrast': ?colors.accentContrast,
      };
    }
    if (override.fonts case final fonts?) {
      overrideJson['fonts'] = {
        'headline': ?fonts.headline,
        'body': ?fonts.body,
      };
    }
    result['brandOverride'] = overrideJson;
  }

  return result;
}

/// Compact semantic reference supplied to each slide-composition request.
Map<String, Object?> serializeDeckThemeForSlidePrompt(
  DeckThemeReference theme,
) => {'id': theme.id, 'version': theme.version, 'density': theme.density};

/// Projects a canonical plan back into the model's repair-only draft shape.
Map<String, Object?> serializeDeckPlanDraftForRepair(DeckPlan plan) => {
  'topic': plan.topic,
  'story': plan.story,
  'theme': {'id': plan.theme.id},
  'sections': [for (final section in plan.sections) section.toJson()],
  'slides': [
    for (final slide in plan.slides) serializeDeckPlanSlideDraft(slide),
  ],
};

Map<String, Object?> serializeDeckPlanSlideDraft(DeckPlanSlide slide) => {
  'key': slide.key,
  'title': slide.title,
  'sectionKey': slide.sectionKey,
  'assertion': slide.assertion,
  'contentUnits': slide.contentUnits,
  'narrativeRole': slide.narrativeRole,
  'composition': slide.composition,
  if (slide.elements case final elements?)
    'elements': [for (final element in elements) element.toJson()],
};
