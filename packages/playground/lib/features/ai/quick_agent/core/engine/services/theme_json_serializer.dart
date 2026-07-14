import '../schemas/deck_schemas.dart';
import '../schemas/outline_schema.dart';

/// Serializes the canonical theme reference for persisted artifacts.
Map<String, Object?> serializeDeckThemeReference(DeckThemeReferenceType theme) {
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
  DeckThemeReferenceType theme,
) => {'id': theme.id, 'version': theme.version, 'density': theme.density};

/// Projects a canonical plan back into the model's repair-only draft shape.
Map<String, Object?> serializeDeckPlanDraftForRepair(DeckPlanType plan) =>
    Map<String, Object?>.of(plan)..['theme'] = {'id': plan.theme.id};
