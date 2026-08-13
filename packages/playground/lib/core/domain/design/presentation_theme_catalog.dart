import 'presentation_color_contrast.dart';
import 'presentation_typography_catalog.dart';

const presentationThemeDirections = [
  'editorial',
  'minimal',
  'bold',
  'technical',
  'playful',
];

const presentationThemeDensityProfiles = ['spacious', 'balanced', 'compact'];

const presentationThemeTypeScales = ['dramatic', 'balanced', 'dense'];

const defaultPresentationThemeIds = [
  'editorial-midnight',
  'technical-paper',
  'bold-product',
  'warm-editorial',
  'nordic-air',
  'monochrome-grid',
  'signal-studio',
  'playful-learning',
  'data-noir',
  'civic-blueprint',
  'organic-sage',
  'retro-poster',
];

/// Stable representative trio used by static Wizard examples and smoke tests.
const featuredPresentationThemeIds = [
  'editorial-midnight',
  'technical-paper',
  'bold-product',
];

enum PresentationThemeBrightness { light, dark }

const presentationThemeTreatmentNames = {
  'hero',
  'section',
  'content',
  'data',
  'quote',
  'visual',
  'closing',
};

enum PresentationThemeColorRole { background, surface, surfaceAlt, accent }

enum PresentationThemeTextColorRole { heading, body, accent, accentContrast }

enum PresentationThemeBlockStyle { none, tonal, outlined }

enum PresentationThemeSurfaceStyle { flat, tonal, outlined }

enum PresentationThemeDecorativeStyle { none, rule, frame, grid, poster }

/// Renderer-safe semantic styling for one named slide treatment.
final class PresentationThemeTreatmentRecipe {
  final PresentationThemeColorRole background;
  final PresentationThemeTextColorRole heading;
  final PresentationThemeTextColorRole body;
  final double headlineScale;
  final bool italicHeadline;
  final PresentationThemeBlockStyle blockStyle;

  const PresentationThemeTreatmentRecipe({
    required this.background,
    required this.heading,
    required this.body,
    required this.headlineScale,
    this.italicHeadline = false,
    this.blockStyle = PresentationThemeBlockStyle.none,
  });
}

/// Complete, typed recipe for all seven supported semantic slide treatments.
final class PresentationThemeTreatmentSet {
  final PresentationThemeTreatmentRecipe hero;
  final PresentationThemeTreatmentRecipe section;
  final PresentationThemeTreatmentRecipe content;
  final PresentationThemeTreatmentRecipe data;
  final PresentationThemeTreatmentRecipe quote;
  final PresentationThemeTreatmentRecipe visual;
  final PresentationThemeTreatmentRecipe closing;

  const PresentationThemeTreatmentSet({
    required this.hero,
    required this.section,
    required this.content,
    required this.data,
    required this.quote,
    required this.visual,
    required this.closing,
  });

  Set<String> get names => presentationThemeTreatmentNames;

  Map<String, PresentationThemeTreatmentRecipe> get byName => .unmodifiable({
    'hero': hero,
    'section': section,
    'content': content,
    'data': data,
    'quote': quote,
    'visual': visual,
    'closing': closing,
  });
}

/// Spacing, shape, component, and treatment values owned by the renderer.
final class PresentationThemeRuntimeRecipe {
  final double spacingScale;
  final double cornerRadius;
  final double borderWidth;
  final double quoteRuleWidth;
  final PresentationThemeSurfaceStyle surfaceStyle;
  final PresentationThemeDecorativeStyle decorativeStyle;
  final PresentationThemeTreatmentSet treatments;

  const PresentationThemeRuntimeRecipe({
    required this.spacingScale,
    required this.cornerRadius,
    required this.borderWidth,
    required this.quoteRuleWidth,
    required this.surfaceStyle,
    required this.decorativeStyle,
    required this.treatments,
  });
}

/// Renderer-owned semantic palette for one presentation theme.
final class PresentationThemePalette {
  final String background;
  final String surface;
  final String surfaceAlt;
  final String heading;
  final String body;
  final String accent;
  final String accentContrast;

  const PresentationThemePalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.heading,
    required this.body,
    required this.accent,
    required this.accentContrast,
  });

  List<String> get previewColors => [background, accent, heading, body];

  PresentationThemePalette apply(PresentationThemeBrandOverride override) =>
      .new(
        background: override.background ?? background,
        surface: override.surface ?? surface,
        surfaceAlt: override.surfaceAlt ?? surfaceAlt,
        heading: override.heading ?? heading,
        body: override.body ?? body,
        accent: override.accent ?? accent,
        accentContrast: override.accentContrast ?? accentContrast,
      );
}

/// Complete safe inputs consumed by the parameterized runtime theme factory.
final class PresentationThemeRecipe {
  final PresentationThemePalette palette;
  final String headlineFamily;
  final String bodyFamily;
  final String direction;
  final String defaultDensity;
  final String typeScale;
  final PresentationThemeRuntimeRecipe runtime;

  const PresentationThemeRecipe({
    required this.palette,
    required this.headlineFamily,
    required this.bodyFamily,
    required this.direction,
    required this.defaultDensity,
    required this.typeScale,
    required this.runtime,
  });
}

/// Exact user-supplied palette and typography constraints layered on a theme.
final class PresentationThemeBrandOverride {
  final String? background;
  final String? surface;
  final String? surfaceAlt;
  final String? heading;
  final String? body;
  final String? accent;
  final String? accentContrast;
  final String? headlineFamily;
  final String? bodyFamily;

  const PresentationThemeBrandOverride({
    this.background,
    this.surface,
    this.surfaceAlt,
    this.heading,
    this.body,
    this.accent,
    this.accentContrast,
    this.headlineFamily,
    this.bodyFamily,
  });

  bool get isEmpty =>
      background == null &&
      surface == null &&
      surfaceAlt == null &&
      heading == null &&
      body == null &&
      accent == null &&
      accentContrast == null &&
      headlineFamily == null &&
      bodyFamily == null;
}

/// One described, versioned theme with selection metadata and runtime recipe.
final class PresentationThemeDescriptor {
  final String id;
  final int version;
  final String title;
  final String description;
  final Set<String> directionTags;
  final Set<String> moodTags;
  final Set<String> audienceTags;
  final Set<String> contentTags;
  final PresentationThemeBrightness brightness;
  final Set<String> supportedDensities;
  final PresentationThemeRecipe recipe;

  const PresentationThemeDescriptor({
    required this.id,
    required this.version,
    required this.title,
    required this.description,
    required this.directionTags,
    required this.moodTags,
    required this.audienceTags,
    required this.contentTags,
    required this.brightness,
    required this.supportedDensities,
    required this.recipe,
  });

  /// Compact candidate payload supplied to the outline model.
  Map<String, Object?> toModelCandidate() {
    final tags = <String>{
      ...directionTags.toList()..sort(),
      ...moodTags.toList()..sort(),
      ...audienceTags.toList()..sort(),
      ...contentTags.toList()..sort(),
      brightness.name,
      ...supportedDensities.toList()..sort(),
    }.toList()..sort();

    return {'id': id, 'title': title, 'description': description, 'tags': tags};
  }
}

/// Typed inputs used by the local deterministic theme selector.
final class PresentationThemeSelectionCriteria {
  final String userIntent;
  final String? explicitThemeId;
  final String? designDirection;
  final String? density;
  final String? audience;
  final String? approach;

  const PresentationThemeSelectionCriteria({
    required this.userIntent,
    this.explicitThemeId,
    this.designDirection,
    this.density,
    this.audience,
    this.approach,
  });
}

/// A canonical theme reference resolved into exact renderer-owned values.
final class ResolvedPresentationTheme {
  final PresentationThemeDescriptor descriptor;
  final PresentationThemePalette palette;
  final String headlineFamily;
  final String bodyFamily;
  final String density;

  const ResolvedPresentationTheme({
    required this.descriptor,
    required this.palette,
    required this.headlineFamily,
    required this.bodyFamily,
    required this.density,
  });

  String get direction => descriptor.recipe.direction;

  String get typeScale => descriptor.recipe.typeScale;
}

/// Injectable registry, selector, and exact-version resolver for deck themes.
final class PresentationThemeCatalog {
  final List<PresentationThemeDescriptor> themes;
  final Map<String, PresentationThemeDescriptor> _byVersion = {};
  final Map<String, PresentationThemeDescriptor> _currentById = {};

  PresentationThemeCatalog(Iterable<PresentationThemeDescriptor> themes)
    : themes = List.unmodifiable(themes) {
    if (this.themes.isEmpty) {
      throw ArgumentError('Presentation theme catalog cannot be empty.');
    }
    for (final theme in this.themes) {
      _validateDescriptor(theme);
      final versionKey = _versionKey(theme.id, theme.version);
      if (_byVersion.containsKey(versionKey)) {
        throw ArgumentError(
          'Duplicate presentation theme reference "$versionKey".',
        );
      }
      _byVersion[versionKey] = theme;
      final current = _currentById[theme.id];
      if (current == null || current.version < theme.version) {
        _currentById[theme.id] = theme;
      }
    }
  }

  factory PresentationThemeCatalog.withDefaults() =>
      defaultPresentationThemeCatalog;

  /// Latest descriptor for every ID, preserving the catalog's declared order.
  List<PresentationThemeDescriptor> get currentThemes => .unmodifiable(
    themes.where((theme) => identical(current(theme.id), theme)),
  );

  PresentationThemeDescriptor? current(String id) => _currentById[id.trim()];

  /// Returns a stable three-to-five candidate shortlist without a model call.
  List<PresentationThemeDescriptor> shortlist(
    PresentationThemeSelectionCriteria criteria, {
    int maxCandidates = 5,
  }) {
    if (maxCandidates < 1 || maxCandidates > 5) {
      throw ArgumentError.value(
        maxCandidates,
        'maxCandidates',
        'Must be between 1 and 5.',
      );
    }
    final explicit = criteria.explicitThemeId?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      final selected = current(explicit);
      if (selected == null) {
        throw ArgumentError('Unknown presentation theme "$explicit".');
      }

      return [selected];
    }

    var candidates = _currentById.values.toList(growable: false);
    final directionTokens = _tokens(criteria.designDirection ?? '');
    final requestedDirections = presentationThemeDirections
        .where(directionTokens.contains)
        .toSet();
    if (requestedDirections.isNotEmpty) {
      candidates = candidates
          .where(
            (theme) => theme.directionTags.any(requestedDirections.contains),
          )
          .toList(growable: false);
    }

    final requestedBrightness = PresentationThemeBrightness.values
        .where((brightness) => directionTokens.contains(brightness.name))
        .toSet();
    if (requestedBrightness.isNotEmpty) {
      candidates = candidates
          .where((theme) => requestedBrightness.contains(theme.brightness))
          .toList(growable: false);
    }

    final density = criteria.density?.trim();
    if (density != null && density.isNotEmpty) {
      candidates = candidates
          .where((theme) => theme.supportedDensities.contains(density))
          .toList(growable: false);
    }
    if (candidates.isEmpty) {
      throw ArgumentError(
        'No presentation theme satisfies the requested design constraints.',
      );
    }

    final relevanceTokens = _tokens(
      [
        criteria.userIntent,
        criteria.audience,
        criteria.approach,
        criteria.designDirection,
      ].whereType<String>().join(' '),
    );
    final catalogOrder = {
      for (final (index, theme) in themes.indexed)
        _versionKey(theme.id, theme.version): index,
    };
    final scored =
        candidates
            .map(
              (theme) => (
                theme: theme,
                score: _score(theme, relevanceTokens),
                order: catalogOrder[_versionKey(theme.id, theme.version)]!,
              ),
            )
            .toList()
          ..sort((first, second) {
            final score = second.score.compareTo(first.score);

            return score == 0 ? first.order.compareTo(second.order) : score;
          });

    final diverse = <PresentationThemeDescriptor>[];
    final usedDirections = <String>{};
    for (final entry in scored) {
      if (usedDirections.add(entry.theme.recipe.direction)) {
        diverse.add(entry.theme);
      }
      if (diverse.length == maxCandidates) return List.unmodifiable(diverse);
    }
    for (final entry in scored) {
      if (!diverse.contains(entry.theme)) diverse.add(entry.theme);
      if (diverse.length == maxCandidates) break;
    }

    return List.unmodifiable(diverse);
  }

  /// Resolves one exact ID/version and applies only validated user overrides.
  ResolvedPresentationTheme resolve({
    required String id,
    required int version,
    required PresentationTypographyCatalog typographyCatalog,
    String? density,
    PresentationThemeBrandOverride brandOverride =
        const PresentationThemeBrandOverride(),
  }) {
    final descriptor = _byVersion[_versionKey(id, version)];
    if (descriptor == null) {
      final currentVersion = current(id)?.version;
      final detail = currentVersion == null
          ? 'The theme ID is unknown.'
          : 'Current catalog version is $currentVersion.';
      throw ArgumentError(
        'Unknown or stale presentation theme "$id@$version". $detail',
      );
    }
    final resolvedDensity = density ?? descriptor.recipe.defaultDensity;
    if (!descriptor.supportedDensities.contains(resolvedDensity)) {
      throw ArgumentError(
        'Theme "$id@$version" does not support density "$resolvedDensity".',
      );
    }

    final headline = _requireFont(
      brandOverride.headlineFamily ?? descriptor.recipe.headlineFamily,
      .headline,
      typographyCatalog,
    );
    final body = _requireFont(
      brandOverride.bodyFamily ?? descriptor.recipe.bodyFamily,
      .body,
      typographyCatalog,
    );
    final palette = descriptor.recipe.palette.apply(brandOverride);
    _validatePalette(palette, label: '$id@$version');
    _validateRuntimeRecipe(
      descriptor.recipe.runtime,
      palette,
      label: '$id@$version',
    );

    return ResolvedPresentationTheme(
      descriptor: descriptor,
      palette: palette,
      headlineFamily: headline.family,
      bodyFamily: body.family,
      density: resolvedDensity,
    );
  }
}

PresentationFontDescriptor _requireFont(
  String family,
  PresentationFontRole role,
  PresentationTypographyCatalog catalog,
) {
  final descriptor = catalog.resolve(family);
  if (descriptor == null || !descriptor.roles.contains(role)) {
    throw ArgumentError(
      '${role == .headline ? 'Headline' : 'Body'} font '
      '"$family" is not registered for ${role.name} use.',
    );
  }

  return descriptor;
}

void _validateDescriptor(PresentationThemeDescriptor theme) {
  if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(theme.id)) {
    throw ArgumentError('Theme ID "${theme.id}" must use kebab-case.');
  }
  if (theme.version < 1) {
    throw ArgumentError('Theme "${theme.id}" must have a positive version.');
  }
  if (theme.title.trim().isEmpty || theme.description.trim().isEmpty) {
    throw ArgumentError(
      'Theme "${theme.id}" requires a title and concrete description.',
    );
  }
  if (!presentationThemeDirections.contains(theme.recipe.direction)) {
    throw ArgumentError(
      'Theme "${theme.id}" has unsupported direction '
      '"${theme.recipe.direction}".',
    );
  }
  if (!presentationThemeTypeScales.contains(theme.recipe.typeScale)) {
    throw ArgumentError(
      'Theme "${theme.id}" has unsupported type scale '
      '"${theme.recipe.typeScale}".',
    );
  }
  if (theme.directionTags.isEmpty ||
      !theme.directionTags.contains(theme.recipe.direction)) {
    throw ArgumentError(
      'Theme "${theme.id}" must tag its resolved visual direction.',
    );
  }
  if (theme.supportedDensities.isEmpty ||
      !theme.supportedDensities.contains(theme.recipe.defaultDensity) ||
      theme.supportedDensities.any(
        (density) => !presentationThemeDensityProfiles.contains(density),
      )) {
    throw ArgumentError(
      'Theme "${theme.id}" has invalid supported density metadata.',
    );
  }
  _validatePalette(theme.recipe.palette, label: '${theme.id}@${theme.version}');
  _validateRuntimeRecipe(
    theme.recipe.runtime,
    theme.recipe.palette,
    label: '${theme.id}@${theme.version}',
  );
}

void _validatePalette(
  PresentationThemePalette palette, {
  required String label,
}) {
  final colors = {
    'background': palette.background,
    'surface': palette.surface,
    'surfaceAlt': palette.surfaceAlt,
    'heading': palette.heading,
    'body': palette.body,
    'accent': palette.accent,
    'accentContrast': palette.accentContrast,
  };
  for (final entry in colors.entries) {
    if (!RegExp(
      r'^#[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?$',
    ).hasMatch(entry.value)) {
      throw ArgumentError(
        'Theme "$label" has invalid ${entry.key} color "${entry.value}".',
      );
    }
  }
  _requireContrast(
    palette.heading,
    palette.background,
    3,
    '$label heading/background',
  );
  _requireContrast(
    palette.body,
    palette.background,
    4.5,
    '$label body/background',
  );
  _requireContrast(palette.body, palette.surface, 4.5, '$label body/surface');
  _requireContrast(
    palette.body,
    palette.surfaceAlt,
    4.5,
    '$label body/surfaceAlt',
  );
  _requireContrast(
    palette.accentContrast,
    palette.accent,
    4.5,
    '$label accent contrast',
  );
}

void _validateRuntimeRecipe(
  PresentationThemeRuntimeRecipe runtime,
  PresentationThemePalette palette, {
  required String label,
}) {
  if (runtime.spacingScale < 0.8 || runtime.spacingScale > 1.2) {
    throw ArgumentError(
      'Theme "$label" spacingScale must be between 0.8 and 1.2.',
    );
  }
  if (runtime.cornerRadius < 0 || runtime.cornerRadius > 32) {
    throw ArgumentError(
      'Theme "$label" cornerRadius must be between 0 and 32.',
    );
  }
  if (runtime.borderWidth < 0 || runtime.borderWidth > 3) {
    throw ArgumentError('Theme "$label" borderWidth must be between 0 and 3.');
  }
  if (runtime.quoteRuleWidth < 0 || runtime.quoteRuleWidth > 12) {
    throw ArgumentError(
      'Theme "$label" quoteRuleWidth must be between 0 and 12.',
    );
  }

  for (final entry in runtime.treatments.byName.entries) {
    final treatment = entry.value;
    if (treatment.headlineScale < 0.7 || treatment.headlineScale > 1.25) {
      throw ArgumentError(
        'Theme "$label" ${entry.key} headlineScale must be between '
        '0.7 and 1.25.',
      );
    }
    final background = _resolveBackgroundColor(treatment.background, palette);
    _requireContrast(
      _resolveTextColor(treatment.heading, palette),
      background,
      3,
      '$label ${entry.key} heading',
    );
    _requireContrast(
      _resolveTextColor(treatment.body, palette),
      background,
      4.5,
      '$label ${entry.key} body',
    );
  }
}

String _resolveBackgroundColor(
  PresentationThemeColorRole role,
  PresentationThemePalette palette,
) => switch (role) {
  .background => palette.background,
  .surface => palette.surface,
  .surfaceAlt => palette.surfaceAlt,
  .accent => palette.accent,
};

String _resolveTextColor(
  PresentationThemeTextColorRole role,
  PresentationThemePalette palette,
) => switch (role) {
  .heading => palette.heading,
  .body => palette.body,
  .accent => palette.accent,
  .accentContrast => palette.accentContrast,
};

void _requireContrast(
  String foreground,
  String background,
  double minimum,
  String label,
) {
  final ratio = calculatePresentationContrast(foreground, background);
  if (ratio < minimum) {
    throw ArgumentError(
      '$label is ${ratio.toStringAsFixed(2)}:1; expected at least '
      '${minimum.toStringAsFixed(1)}:1.',
    );
  }
}

int _score(PresentationThemeDescriptor theme, Set<String> relevanceTokens) {
  final searchable = _tokens(
    [
      theme.title,
      theme.description,
      ...theme.directionTags,
      ...theme.moodTags,
      ...theme.audienceTags,
      ...theme.contentTags,
    ].join(' '),
  );

  return searchable.intersection(relevanceTokens).length;
}

Set<String> _tokens(String value) => value
    .toLowerCase()
    .split(RegExp(r'[^a-z0-9]+'))
    .where((token) => token.length > 2 || token == 'ai')
    .toSet();

String _versionKey(String id, int version) => '$id@$version';

const _editorialTreatments = PresentationThemeTreatmentSet(
  hero: PresentationThemeTreatmentRecipe(
    background: .surface,
    heading: .heading,
    body: .body,
    headlineScale: 1.1,
    italicHeadline: true,
  ),
  section: PresentationThemeTreatmentRecipe(
    background: .accent,
    heading: .accentContrast,
    body: .accentContrast,
    headlineScale: 0.95,
  ),
  content: PresentationThemeTreatmentRecipe(
    background: .background,
    heading: .heading,
    body: .body,
    headlineScale: 0.8,
  ),
  data: PresentationThemeTreatmentRecipe(
    background: .surface,
    heading: .heading,
    body: .body,
    headlineScale: 0.85,
    blockStyle: .tonal,
  ),
  quote: PresentationThemeTreatmentRecipe(
    background: .surface,
    heading: .accent,
    body: .body,
    headlineScale: 0.9,
    italicHeadline: true,
  ),
  visual: PresentationThemeTreatmentRecipe(
    background: .surfaceAlt,
    heading: .heading,
    body: .body,
    headlineScale: 0.8,
  ),
  closing: PresentationThemeTreatmentRecipe(
    background: .accent,
    heading: .accentContrast,
    body: .accentContrast,
    headlineScale: 0.95,
  ),
);

const _technicalTreatments = PresentationThemeTreatmentSet(
  hero: PresentationThemeTreatmentRecipe(
    background: .background,
    heading: .heading,
    body: .body,
    headlineScale: 1,
  ),
  section: PresentationThemeTreatmentRecipe(
    background: .accent,
    heading: .accentContrast,
    body: .accentContrast,
    headlineScale: 0.9,
  ),
  content: PresentationThemeTreatmentRecipe(
    background: .background,
    heading: .heading,
    body: .body,
    headlineScale: 0.8,
  ),
  data: PresentationThemeTreatmentRecipe(
    background: .surface,
    heading: .heading,
    body: .body,
    headlineScale: 0.82,
    blockStyle: .outlined,
  ),
  quote: PresentationThemeTreatmentRecipe(
    background: .background,
    heading: .accent,
    body: .body,
    headlineScale: 0.85,
  ),
  visual: PresentationThemeTreatmentRecipe(
    background: .surfaceAlt,
    heading: .heading,
    body: .body,
    headlineScale: 0.8,
    blockStyle: .outlined,
  ),
  closing: PresentationThemeTreatmentRecipe(
    background: .accent,
    heading: .accentContrast,
    body: .accentContrast,
    headlineScale: 0.9,
  ),
);

const _boldTreatments = PresentationThemeTreatmentSet(
  hero: PresentationThemeTreatmentRecipe(
    background: .accent,
    heading: .accentContrast,
    body: .accentContrast,
    headlineScale: 1,
  ),
  section: PresentationThemeTreatmentRecipe(
    background: .surfaceAlt,
    heading: .heading,
    body: .body,
    headlineScale: 0.95,
    blockStyle: .tonal,
  ),
  content: PresentationThemeTreatmentRecipe(
    background: .background,
    heading: .heading,
    body: .body,
    headlineScale: 0.82,
  ),
  data: PresentationThemeTreatmentRecipe(
    background: .surface,
    heading: .heading,
    body: .body,
    headlineScale: 0.85,
    blockStyle: .tonal,
  ),
  quote: PresentationThemeTreatmentRecipe(
    background: .background,
    heading: .accent,
    body: .body,
    headlineScale: 1,
  ),
  visual: PresentationThemeTreatmentRecipe(
    background: .surfaceAlt,
    heading: .heading,
    body: .body,
    headlineScale: 0.88,
    blockStyle: .tonal,
  ),
  closing: PresentationThemeTreatmentRecipe(
    background: .accent,
    heading: .accentContrast,
    body: .accentContrast,
    headlineScale: 1,
  ),
);

const _minimalTreatments = PresentationThemeTreatmentSet(
  hero: PresentationThemeTreatmentRecipe(
    background: .background,
    heading: .heading,
    body: .body,
    headlineScale: 0.92,
  ),
  section: PresentationThemeTreatmentRecipe(
    background: .surfaceAlt,
    heading: .heading,
    body: .body,
    headlineScale: 0.86,
  ),
  content: PresentationThemeTreatmentRecipe(
    background: .background,
    heading: .heading,
    body: .body,
    headlineScale: 0.78,
  ),
  data: PresentationThemeTreatmentRecipe(
    background: .surface,
    heading: .heading,
    body: .body,
    headlineScale: 0.8,
    blockStyle: .outlined,
  ),
  quote: PresentationThemeTreatmentRecipe(
    background: .background,
    heading: .accent,
    body: .body,
    headlineScale: 0.88,
    italicHeadline: true,
  ),
  visual: PresentationThemeTreatmentRecipe(
    background: .surfaceAlt,
    heading: .heading,
    body: .body,
    headlineScale: 0.78,
  ),
  closing: PresentationThemeTreatmentRecipe(
    background: .surface,
    heading: .heading,
    body: .body,
    headlineScale: 0.9,
  ),
);

const _playfulTreatments = PresentationThemeTreatmentSet(
  hero: PresentationThemeTreatmentRecipe(
    background: .surfaceAlt,
    heading: .heading,
    body: .body,
    headlineScale: 1.08,
  ),
  section: PresentationThemeTreatmentRecipe(
    background: .accent,
    heading: .accentContrast,
    body: .accentContrast,
    headlineScale: 0.95,
  ),
  content: PresentationThemeTreatmentRecipe(
    background: .background,
    heading: .heading,
    body: .body,
    headlineScale: 0.8,
  ),
  data: PresentationThemeTreatmentRecipe(
    background: .surface,
    heading: .heading,
    body: .body,
    headlineScale: 0.86,
    blockStyle: .tonal,
  ),
  quote: PresentationThemeTreatmentRecipe(
    background: .surfaceAlt,
    heading: .accent,
    body: .body,
    headlineScale: 0.95,
    italicHeadline: true,
  ),
  visual: PresentationThemeTreatmentRecipe(
    background: .surfaceAlt,
    heading: .heading,
    body: .body,
    headlineScale: 0.85,
    blockStyle: .tonal,
  ),
  closing: PresentationThemeTreatmentRecipe(
    background: .accent,
    heading: .accentContrast,
    body: .accentContrast,
    headlineScale: 1,
  ),
);

const _defaultPresentationThemes = [
  PresentationThemeDescriptor(
    id: 'editorial-midnight',
    version: 1,
    title: 'Editorial Midnight',
    description:
        'Dark cinematic editorial system with high-contrast display '
        'typography, generous pacing, and warm accent restraint; best for '
        'leadership narratives and research-led stories.',
    directionTags: {'editorial'},
    moodTags: {'cinematic', 'restrained', 'sophisticated', 'warm'},
    audienceTags: {'leadership', 'executive', 'research'},
    contentTags: {'narrative', 'strategy', 'insight'},
    brightness: .dark,
    supportedDensities: {'spacious', 'balanced'},
    recipe: PresentationThemeRecipe(
      palette: PresentationThemePalette(
        background: '#0D1626',
        surface: '#15233A',
        surfaceAlt: '#20324D',
        heading: '#FFF6E8',
        body: '#DCE5F2',
        accent: '#E4B363',
        accentContrast: '#171006',
      ),
      headlineFamily: 'Playfair Display',
      bodyFamily: 'Inter',
      direction: 'editorial',
      defaultDensity: 'spacious',
      typeScale: 'dramatic',
      runtime: PresentationThemeRuntimeRecipe(
        spacingScale: 1.1,
        cornerRadius: 8,
        borderWidth: 1,
        quoteRuleWidth: 6,
        surfaceStyle: .tonal,
        decorativeStyle: .rule,
        treatments: _editorialTreatments,
      ),
    ),
  ),
  PresentationThemeDescriptor(
    id: 'technical-paper',
    version: 1,
    title: 'Technical Paper',
    description:
        'Light precision system with geometric hierarchy, compact data '
        'surfaces, and disciplined grids; best for product decisions, '
        'comparisons, and technical evidence.',
    directionTags: {'technical', 'minimal'},
    moodTags: {'precise', 'clear', 'structured', 'warm'},
    audienceTags: {'product', 'engineering', 'operations'},
    contentTags: {'data', 'comparison', 'evidence', 'technical'},
    brightness: .light,
    supportedDensities: {'balanced', 'compact'},
    recipe: PresentationThemeRecipe(
      palette: PresentationThemePalette(
        background: '#F5F7FA',
        surface: '#FFFFFF',
        surfaceAlt: '#E7EDF4',
        heading: '#102A43',
        body: '#243B53',
        accent: '#0967D2',
        accentContrast: '#FFFFFF',
      ),
      headlineFamily: 'Space Grotesk',
      bodyFamily: 'Open Sans',
      direction: 'technical',
      defaultDensity: 'balanced',
      typeScale: 'balanced',
      runtime: PresentationThemeRuntimeRecipe(
        spacingScale: 0.95,
        cornerRadius: 6,
        borderWidth: 1.5,
        quoteRuleWidth: 4,
        surfaceStyle: .outlined,
        decorativeStyle: .frame,
        treatments: _technicalTreatments,
      ),
    ),
  ),
  PresentationThemeDescriptor(
    id: 'bold-product',
    version: 1,
    title: 'Bold Product',
    description:
        'Dark high-energy product system with oversized headlines, saturated '
        'accents, and assertive modular cards; best for launches, demos, and '
        'developer audiences.',
    directionTags: {'bold', 'playful'},
    moodTags: {'energetic', 'assertive', 'modern'},
    audienceTags: {'developer', 'product', 'technology'},
    contentTags: {'launch', 'demo', 'platform', 'visual'},
    brightness: .dark,
    supportedDensities: {'spacious', 'balanced'},
    recipe: PresentationThemeRecipe(
      palette: PresentationThemePalette(
        background: '#160F1B',
        surface: '#25172E',
        surfaceAlt: '#3A2048',
        heading: '#FFF8E7',
        body: '#E9DDF0',
        accent: '#FFB000',
        accentContrast: '#1C1000',
      ),
      headlineFamily: 'Montserrat',
      bodyFamily: 'DM Sans',
      direction: 'bold',
      defaultDensity: 'balanced',
      typeScale: 'dramatic',
      runtime: PresentationThemeRuntimeRecipe(
        spacingScale: 1,
        cornerRadius: 22,
        borderWidth: 0,
        quoteRuleWidth: 8,
        surfaceStyle: .tonal,
        decorativeStyle: .poster,
        treatments: _boldTreatments,
      ),
    ),
  ),
  PresentationThemeDescriptor(
    id: 'warm-editorial',
    version: 1,
    title: 'Warm Editorial',
    description:
        'Light book-inspired editorial system with warm paper surfaces, '
        'contemporary serif hierarchy, and measured pacing; best for human '
        'stories, culture, and thoughtful brand narratives.',
    directionTags: {'editorial'},
    moodTags: {'warm', 'human', 'thoughtful', 'literary'},
    audienceTags: {'leadership', 'culture', 'brand'},
    contentTags: {'narrative', 'story', 'research'},
    brightness: .light,
    supportedDensities: {'spacious', 'balanced'},
    recipe: PresentationThemeRecipe(
      palette: PresentationThemePalette(
        background: '#FFF8EF',
        surface: '#FFFFFF',
        surfaceAlt: '#F3E5D6',
        heading: '#3A2318',
        body: '#51382C',
        accent: '#8C3D2E',
        accentContrast: '#FFFFFF',
      ),
      headlineFamily: 'Lora',
      bodyFamily: 'Source Serif 4',
      direction: 'editorial',
      defaultDensity: 'balanced',
      typeScale: 'balanced',
      runtime: PresentationThemeRuntimeRecipe(
        spacingScale: 1.08,
        cornerRadius: 4,
        borderWidth: 1,
        quoteRuleWidth: 5,
        surfaceStyle: .flat,
        decorativeStyle: .rule,
        treatments: _editorialTreatments,
      ),
    ),
  ),
  PresentationThemeDescriptor(
    id: 'nordic-air',
    version: 1,
    title: 'Nordic Air',
    description:
        'Bright minimal system with open spacing, softly rounded geometry, and '
        'quiet green accents; best for service design, wellbeing, and calm '
        'product explanations.',
    directionTags: {'minimal'},
    moodTags: {'calm', 'airy', 'soft', 'modern'},
    audienceTags: {'consumer', 'design', 'leadership'},
    contentTags: {'service', 'wellbeing', 'product', 'overview'},
    brightness: .light,
    supportedDensities: {'spacious', 'balanced'},
    recipe: PresentationThemeRecipe(
      palette: PresentationThemePalette(
        background: '#F6F7F2',
        surface: '#FFFFFF',
        surfaceAlt: '#E4E9E0',
        heading: '#18221C',
        body: '#35443A',
        accent: '#2F6B58',
        accentContrast: '#FFFFFF',
      ),
      headlineFamily: 'Poppins',
      bodyFamily: 'Lato',
      direction: 'minimal',
      defaultDensity: 'spacious',
      typeScale: 'balanced',
      runtime: PresentationThemeRuntimeRecipe(
        spacingScale: 1.15,
        cornerRadius: 20,
        borderWidth: 0.75,
        quoteRuleWidth: 4,
        surfaceStyle: .tonal,
        decorativeStyle: .none,
        treatments: _minimalTreatments,
      ),
    ),
  ),
  PresentationThemeDescriptor(
    id: 'monochrome-grid',
    version: 1,
    title: 'Monochrome Grid',
    description:
        'Dark Swiss-influenced system with monospaced hierarchy, sharp grid '
        'lines, and a single electric accent; best for architecture, systems, '
        'and dense operational frameworks.',
    directionTags: {'minimal'},
    moodTags: {'rigorous', 'graphic', 'monochrome', 'precise'},
    audienceTags: {'design', 'engineering', 'operations'},
    contentTags: {'system', 'framework', 'architecture', 'process'},
    brightness: .dark,
    supportedDensities: {'balanced', 'compact'},
    recipe: PresentationThemeRecipe(
      palette: PresentationThemePalette(
        background: '#0A0A0A',
        surface: '#161616',
        surfaceAlt: '#242424',
        heading: '#FFFFFF',
        body: '#D6D6D6',
        accent: '#D6FF3F',
        accentContrast: '#101400',
      ),
      headlineFamily: 'JetBrains Mono',
      bodyFamily: 'Inter',
      direction: 'minimal',
      defaultDensity: 'compact',
      typeScale: 'dense',
      runtime: PresentationThemeRuntimeRecipe(
        spacingScale: 0.9,
        cornerRadius: 0,
        borderWidth: 2,
        quoteRuleWidth: 6,
        surfaceStyle: .outlined,
        decorativeStyle: .grid,
        treatments: _minimalTreatments,
      ),
    ),
  ),
  PresentationThemeDescriptor(
    id: 'signal-studio',
    version: 1,
    title: 'Signal Studio',
    description:
        'Light poster-like system with condensed headlines, sharp cards, and '
        'high-signal orange accents; best for campaigns, decisive proposals, '
        'and fast-moving launch narratives.',
    directionTags: {'bold'},
    moodTags: {'urgent', 'graphic', 'confident', 'direct'},
    audienceTags: {'marketing', 'sales', 'product'},
    contentTags: {'campaign', 'proposal', 'launch', 'decision'},
    brightness: .light,
    supportedDensities: {'balanced', 'compact'},
    recipe: PresentationThemeRecipe(
      palette: PresentationThemePalette(
        background: '#FFF8F0',
        surface: '#FFFFFF',
        surfaceAlt: '#FFE5CC',
        heading: '#23160F',
        body: '#4A3328',
        accent: '#C74200',
        accentContrast: '#FFFFFF',
      ),
      headlineFamily: 'Oswald',
      bodyFamily: 'Roboto',
      direction: 'bold',
      defaultDensity: 'compact',
      typeScale: 'dramatic',
      runtime: PresentationThemeRuntimeRecipe(
        spacingScale: 0.88,
        cornerRadius: 2,
        borderWidth: 2,
        quoteRuleWidth: 7,
        surfaceStyle: .outlined,
        decorativeStyle: .poster,
        treatments: _boldTreatments,
      ),
    ),
  ),
  PresentationThemeDescriptor(
    id: 'playful-learning',
    version: 1,
    title: 'Playful Learning',
    description:
        'Friendly light system with expressive display type, rounded modules, '
        'and bright violet accents; best for education, community workshops, '
        'and approachable explainers.',
    directionTags: {'playful'},
    moodTags: {'friendly', 'curious', 'optimistic', 'colorful'},
    audienceTags: {'education', 'community', 'consumer'},
    contentTags: {'learning', 'workshop', 'explainer', 'story'},
    brightness: .light,
    supportedDensities: {'spacious', 'balanced'},
    recipe: PresentationThemeRecipe(
      palette: PresentationThemePalette(
        background: '#FFF9E8',
        surface: '#FFFFFF',
        surfaceAlt: '#EDE7FF',
        heading: '#33245C',
        body: '#4D4166',
        accent: '#6C4AD9',
        accentContrast: '#FFFFFF',
      ),
      headlineFamily: 'Lobster',
      bodyFamily: 'Open Sans',
      direction: 'playful',
      defaultDensity: 'balanced',
      typeScale: 'balanced',
      runtime: PresentationThemeRuntimeRecipe(
        spacingScale: 1.05,
        cornerRadius: 28,
        borderWidth: 0,
        quoteRuleWidth: 8,
        surfaceStyle: .tonal,
        decorativeStyle: .poster,
        treatments: _playfulTreatments,
      ),
    ),
  ),
  PresentationThemeDescriptor(
    id: 'data-noir',
    version: 1,
    title: 'Data Noir',
    description:
        'Dark analytical system with monospaced headings, compact evidence '
        'surfaces, and luminous teal signals; best for security, telemetry, '
        'developer tooling, and data-heavy reviews.',
    directionTags: {'technical'},
    moodTags: {'analytical', 'focused', 'precise', 'modern'},
    audienceTags: {'engineering', 'security', 'data'},
    contentTags: {'metrics', 'telemetry', 'evidence', 'technical'},
    brightness: .dark,
    supportedDensities: {'balanced', 'compact'},
    recipe: PresentationThemeRecipe(
      palette: PresentationThemePalette(
        background: '#071014',
        surface: '#0D1C22',
        surfaceAlt: '#15303A',
        heading: '#E9FAFF',
        body: '#C7DFE8',
        accent: '#35D0BA',
        accentContrast: '#041310',
      ),
      headlineFamily: 'JetBrains Mono',
      bodyFamily: 'Roboto',
      direction: 'technical',
      defaultDensity: 'compact',
      typeScale: 'dense',
      runtime: PresentationThemeRuntimeRecipe(
        spacingScale: 0.86,
        cornerRadius: 6,
        borderWidth: 1,
        quoteRuleWidth: 4,
        surfaceStyle: .tonal,
        decorativeStyle: .frame,
        treatments: _technicalTreatments,
      ),
    ),
  ),
  PresentationThemeDescriptor(
    id: 'civic-blueprint',
    version: 1,
    title: 'Civic Blueprint',
    description:
        'Light institutional system with serif authority, blueprint-blue rules, '
        'and disciplined evidence panels; best for policy, public programs, '
        'research findings, and implementation plans.',
    directionTags: {'technical'},
    moodTags: {'credible', 'measured', 'structured', 'clear'},
    audienceTags: {'policy', 'public', 'research', 'leadership'},
    contentTags: {'program', 'evidence', 'plan', 'governance'},
    brightness: .light,
    supportedDensities: {'balanced', 'compact'},
    recipe: PresentationThemeRecipe(
      palette: PresentationThemePalette(
        background: '#F2F6FA',
        surface: '#FFFFFF',
        surfaceAlt: '#DCE8F2',
        heading: '#12314A',
        body: '#2F4B60',
        accent: '#1C5D99',
        accentContrast: '#FFFFFF',
      ),
      headlineFamily: 'Source Serif Pro',
      bodyFamily: 'Open Sans',
      direction: 'technical',
      defaultDensity: 'balanced',
      typeScale: 'balanced',
      runtime: PresentationThemeRuntimeRecipe(
        spacingScale: 0.94,
        cornerRadius: 0,
        borderWidth: 1.5,
        quoteRuleWidth: 4,
        surfaceStyle: .outlined,
        decorativeStyle: .rule,
        treatments: _technicalTreatments,
      ),
    ),
  ),
  PresentationThemeDescriptor(
    id: 'organic-sage',
    version: 1,
    title: 'Organic Sage',
    description:
        'Soft natural system with humanist serif hierarchy, generous whitespace, '
        'and grounded sage surfaces; best for sustainability, healthcare, '
        'culture, and purpose-led strategy.',
    directionTags: {'minimal', 'editorial'},
    moodTags: {'natural', 'calm', 'human', 'grounded'},
    audienceTags: {'healthcare', 'sustainability', 'culture', 'leadership'},
    contentTags: {'impact', 'purpose', 'strategy', 'story'},
    brightness: .light,
    supportedDensities: {'spacious', 'balanced'},
    recipe: PresentationThemeRecipe(
      palette: PresentationThemePalette(
        background: '#F5F4ED',
        surface: '#FFFFFF',
        surfaceAlt: '#E3E6D7',
        heading: '#263126',
        body: '#465046',
        accent: '#526B45',
        accentContrast: '#FFFFFF',
      ),
      headlineFamily: 'Lora',
      bodyFamily: 'Lato',
      direction: 'minimal',
      defaultDensity: 'balanced',
      typeScale: 'balanced',
      runtime: PresentationThemeRuntimeRecipe(
        spacingScale: 1.12,
        cornerRadius: 16,
        borderWidth: 0.75,
        quoteRuleWidth: 5,
        surfaceStyle: .flat,
        decorativeStyle: .none,
        treatments: _minimalTreatments,
      ),
    ),
  ),
  PresentationThemeDescriptor(
    id: 'retro-poster',
    version: 1,
    title: 'Retro Poster',
    description:
        'Warm print-inspired system with condensed display headlines, generous '
        'poster pacing, and deep red graphic accents; best for events, culture, '
        'creative pitches, and memorable closing moments.',
    directionTags: {'playful', 'bold'},
    moodTags: {'retro', 'expressive', 'warm', 'graphic'},
    audienceTags: {'creative', 'community', 'marketing'},
    contentTags: {'event', 'culture', 'pitch', 'campaign'},
    brightness: .light,
    supportedDensities: {'spacious', 'balanced'},
    recipe: PresentationThemeRecipe(
      palette: PresentationThemePalette(
        background: '#FFF1D0',
        surface: '#FFE4A8',
        surfaceAlt: '#F4C36A',
        heading: '#2A1A14',
        body: '#4B2D22',
        accent: '#A72B20',
        accentContrast: '#FFFFFF',
      ),
      headlineFamily: 'Oswald',
      bodyFamily: 'DM Sans',
      direction: 'playful',
      defaultDensity: 'spacious',
      typeScale: 'dramatic',
      runtime: PresentationThemeRuntimeRecipe(
        spacingScale: 1.06,
        cornerRadius: 0,
        borderWidth: 2,
        quoteRuleWidth: 10,
        surfaceStyle: .flat,
        decorativeStyle: .poster,
        treatments: _playfulTreatments,
      ),
    ),
  ),
];

/// Shared default catalog; consumers can still inject a scoped catalog in tests
/// or applications that register additional versioned themes.
final defaultPresentationThemeCatalog = PresentationThemeCatalog(
  _defaultPresentationThemes,
);
