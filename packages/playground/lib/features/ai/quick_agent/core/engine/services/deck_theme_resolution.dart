import '../../../../../../core/domain/design/presentation_theme_catalog.dart';
import '../../../../../../core/domain/design/presentation_typography_catalog.dart';
import '../schemas/deck_schemas.dart';
import '../schemas/outline_schema.dart';
import 'deck_generation_request.dart';

/// Builds the eligible shortlist after applying exact local-only constraints.
List<PresentationThemeDescriptor> themeCandidatesForRequest({
  required DeckGenerationRequest request,
  required PresentationThemeCatalog themeCatalog,
  required PresentationTypographyCatalog typographyCatalog,
}) {
  final candidates = themeCatalog.shortlist(
    PresentationThemeSelectionCriteria(
      userIntent: request.userIntent,
      explicitThemeId: request.themeId,
      designDirection: request.designDirection,
      density: request.density,
      audience: request.audience,
      approach: request.approach,
    ),
  );
  final compatible = <PresentationThemeDescriptor>[];
  Object? lastError;
  for (final candidate in candidates) {
    try {
      final reference = buildDeckThemeReference(
        descriptor: candidate,
        request: request,
        typographyCatalog: typographyCatalog,
      );
      resolveDeckThemeMap(
        reference,
        themeCatalog: themeCatalog,
        typographyCatalog: typographyCatalog,
      );
      compatible.add(candidate);
    } catch (error) {
      lastError = error;
    }
  }
  if (compatible.isEmpty) {
    throw ArgumentError(
      'No presentation theme can satisfy the exact user overrides. '
      '${lastError ?? ''}',
    );
  }

  return List.unmodifiable(compatible);
}

/// Parses a model-facing draft and attaches the canonical theme reference.
DeckPlan resolveDeckPlanDraft({
  required Map<String, Object?> draft,
  required List<PresentationThemeDescriptor> candidates,
  required DeckGenerationRequest request,
  required PresentationThemeCatalog themeCatalog,
  required PresentationTypographyCatalog typographyCatalog,
}) {
  final parsed =
      buildDeckPlanDraftSchema(
        candidates.map((candidate) => candidate.id).toList(growable: false),
      ).parse(draft) ??
      (throw ArgumentError('Deck-plan draft cannot be null.'));
  final themeDraft = Map<String, Object?>.from(parsed['theme']! as Map);
  final selectedId = themeDraft['id']! as String;
  final descriptor = candidates.singleWhere(
    (candidate) => candidate.id == selectedId,
    orElse: () => throw ArgumentError(
      'The model selected ineligible presentation theme "$selectedId".',
    ),
  );
  final reference = buildDeckThemeReference(
    descriptor: descriptor,
    request: request,
    typographyCatalog: typographyCatalog,
  );
  resolveDeckThemeMap(
    reference,
    themeCatalog: themeCatalog,
    typographyCatalog: typographyCatalog,
  );

  final slides = (parsed['slides']! as List<Object?>)
      .map((slide) => Map<String, Object?>.from(slide! as Map))
      .toList(growable: false);

  return DeckPlan.parse(
    Map<String, Object?>.of(parsed)
      ..['theme'] = reference
      ..['slides'] = [
        for (final (index, slide) in slides.indexed)
          enrichDeckPlanDraftSlide(
            slide,
            index: index,
            slides: slides,
            density: request.density ?? descriptor.recipe.defaultDensity,
          ),
      ],
  );
}

Map<String, Object?> enrichDeckPlanDraftSlide(
  Map<String, Object?> slide, {
  required int index,
  required List<Map<String, Object?>> slides,
  required String density,
}) {
  final assertion = slide['assertion']! as String;
  final contentUnits = (slide['contentUnits']! as List<Object?>).cast<String>();
  final role = slide['narrativeRole']! as String;
  final composition = slide['composition']! as String;

  return Map.of(slide)
    ..['purpose'] = assertion
    ..['contentBrief'] = contentUnits.join(' ')
    ..['continuity'] = _deriveContinuity(index, slides)
    ..['treatment'] = _deriveTreatment(role, composition)
    ..['density'] = density;
}

String _deriveContinuity(int index, List<Map<String, Object?>> slides) {
  if (slides.length == 1) {
    return 'Open the deck with this idea and establish the through-line.';
  }
  if (index == 0) {
    final nextTitle = slides[1]['title']! as String;

    return 'Open the deck with this idea, then lead into '
        '"$nextTitle".';
  }
  if (index == slides.length - 1) {
    final previousTitle = slides[index - 1]['title']! as String;

    return 'Build from "$previousTitle" and close the deck.';
  }
  final previousTitle = slides[index - 1]['title']! as String;
  final nextTitle = slides[index + 1]['title']! as String;

  return 'Build from "$previousTitle" and lead into "$nextTitle".';
}

String _deriveTreatment(String role, String composition) {
  if (role == 'closing' &&
      const {'title', 'titleLeft', 'quote'}.contains(composition)) {
    return 'closing';
  }
  if (role == 'transition' &&
      const {'title', 'titleLeft'}.contains(composition)) {
    return 'section';
  }

  return switch (composition) {
    'title' => 'hero',
    'quote' => 'quote',
    'metric' || 'table' || 'twoColumn' || 'threeColumn' => 'data',
    'imageLeft' || 'imageRight' || 'imageFullBleed' => 'visual',
    _ => 'content',
  };
}

/// Creates the application-owned canonical reference for one selected theme.
Map<String, Object?> buildDeckThemeReference({
  required PresentationThemeDescriptor descriptor,
  required DeckGenerationRequest request,
  required PresentationTypographyCatalog typographyCatalog,
}) {
  if (request.colors.isNotEmpty && request.colors.length != 3) {
    throw ArgumentError(
      'Palette overrides must contain background, heading, and body colors.',
    );
  }
  final colors = request.colors.isEmpty
      ? null
      : <String, Object?>{
          'background': request.colors[0],
          'heading': request.colors[1],
          'body': request.colors[2],
        };
  final headline = _canonicalFont(
    request.headlineFont,
    .headline,
    typographyCatalog,
  );
  final body = _canonicalFont(request.bodyFont, .body, typographyCatalog);
  final fonts = headline == null && body == null
      ? null
      : <String, Object?>{'headline': ?headline, 'body': ?body};
  final override = colors == null && fonts == null
      ? null
      : <String, Object?>{'colors': ?colors, 'fonts': ?fonts};

  return {
    'id': descriptor.id,
    'version': descriptor.version,
    'density': request.density ?? descriptor.recipe.defaultDensity,
    'brandOverride': ?override,
  };
}

/// Resolves a generated canonical reference into renderer-ready theme values.
ResolvedPresentationTheme resolveDeckThemeReference(
  DeckThemeReference theme, {
  required PresentationThemeCatalog themeCatalog,
  required PresentationTypographyCatalog typographyCatalog,
}) => resolveDeckThemeMap(
  theme.toJson(),
  themeCatalog: themeCatalog,
  typographyCatalog: typographyCatalog,
);

/// Resolves an artifact/reference map without requiring a generated wrapper.
ResolvedPresentationTheme resolveDeckThemeMap(
  Map<String, Object?> theme, {
  required PresentationThemeCatalog themeCatalog,
  required PresentationTypographyCatalog typographyCatalog,
}) {
  final parsed = DeckThemeReference.parse(theme);
  final override = parsed.brandOverride;
  final colors = override?.colors;
  final fonts = override?.fonts;

  return themeCatalog.resolve(
    id: parsed.id,
    version: parsed.version,
    typographyCatalog: typographyCatalog,
    density: parsed.density,
    brandOverride: PresentationThemeBrandOverride(
      background: colors?.background,
      surface: colors?.surface,
      surfaceAlt: colors?.surfaceAlt,
      heading: colors?.heading,
      body: colors?.body,
      accent: colors?.accent,
      accentContrast: colors?.accentContrast,
      headlineFamily: fonts?.headline,
      bodyFamily: fonts?.body,
    ),
  );
}

String? _canonicalFont(
  String? requested,
  PresentationFontRole role,
  PresentationTypographyCatalog catalog,
) {
  if (requested == null) return null;
  final descriptor = catalog.resolve(requested);
  if (descriptor == null || !descriptor.roles.contains(role)) {
    throw ArgumentError(
      '${role == .headline ? 'Headline' : 'Body'} font '
      '"$requested" is not registered for ${role.name} use.',
    );
  }

  return descriptor.family;
}
