/// Semantic role a font is approved to serve in a presentation.
enum PresentationFontRole { headline, body }

/// How a font is made available to the running application.
enum PresentationFontSource { googleFonts, bundled }

/// A font family that can be selected, validated, and rendered by SuperDeck.
final class PresentationFontDescriptor {
  const PresentationFontDescriptor({
    required this.id,
    required this.family,
    required this.description,
    required this.source,
    required this.roles,
    required this.weights,
  });

  final String id;
  final String family;
  final String description;
  final PresentationFontSource source;
  final Set<PresentationFontRole> roles;
  final Set<int> weights;
}

/// Single source of truth for AI generation, Wizard previews, and editor fonts.
final class PresentationTypographyCatalog {
  PresentationTypographyCatalog._(Iterable<PresentationFontDescriptor> fonts)
    : fonts = List.unmodifiable(fonts) {
    for (final font in this.fonts) {
      _register(font.id, font);
      _register(font.family, font);
    }
  }

  factory PresentationTypographyCatalog.withDefaults({
    Iterable<PresentationFontDescriptor> registeredFonts = const [],
  }) => PresentationTypographyCatalog._([
    ..._defaultPresentationFonts,
    ...registeredFonts,
  ]);

  final List<PresentationFontDescriptor> fonts;
  final Map<String, PresentationFontDescriptor> _byName = {};

  PresentationFontDescriptor? resolve(String value) =>
      _byName[_normalize(value)];

  bool supports(String value, PresentationFontRole role) =>
      resolve(value)?.roles.contains(role) ?? false;

  List<PresentationFontDescriptor> forRole(PresentationFontRole role) =>
      fonts.where((font) => font.roles.contains(role)).toList(growable: false);

  List<String> get familyNames =>
      fonts.map((font) => font.family).toList(growable: false);

  void _register(String name, PresentationFontDescriptor font) {
    final key = _normalize(name);
    final existing = _byName[key];
    if (existing != null && existing != font) {
      throw ArgumentError('Duplicate presentation font name "$name".');
    }
    _byName[key] = font;
  }
}

String _normalize(String value) => value
    .trim()
    .replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (match) => '${match.group(1)}-${match.group(2)}',
    )
    .replaceAllMapped(
      RegExp(r'([A-Za-z])([0-9])'),
      (match) => '${match.group(1)}-${match.group(2)}',
    )
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-');

const _bothRoles = {PresentationFontRole.headline, PresentationFontRole.body};
const _headlineRole = {PresentationFontRole.headline};
const _regularWeights = {400, 500, 600, 700};

const _defaultPresentationFonts = <PresentationFontDescriptor>[
  PresentationFontDescriptor(
    id: 'inter',
    family: 'Inter',
    description: 'Neutral, highly readable modern sans',
    source: PresentationFontSource.googleFonts,
    roles: _bothRoles,
    weights: _regularWeights,
  ),
  PresentationFontDescriptor(
    id: 'roboto',
    family: 'Roboto',
    description: 'Practical technical sans with broad weight support',
    source: PresentationFontSource.googleFonts,
    roles: _bothRoles,
    weights: _regularWeights,
  ),
  PresentationFontDescriptor(
    id: 'playfair-display',
    family: 'Playfair Display',
    description: 'High-contrast editorial serif for expressive storytelling',
    source: PresentationFontSource.googleFonts,
    roles: _bothRoles,
    weights: _regularWeights,
  ),
  PresentationFontDescriptor(
    id: 'source-serif-pro',
    family: 'Source Serif Pro',
    description: 'Classic readable serif for editorial and research decks',
    source: PresentationFontSource.googleFonts,
    roles: _bothRoles,
    weights: _regularWeights,
  ),
  PresentationFontDescriptor(
    id: 'jetbrains-mono',
    family: 'JetBrains Mono',
    description: 'Technical monospaced family for developer narratives',
    source: PresentationFontSource.googleFonts,
    roles: _bothRoles,
    weights: _regularWeights,
  ),
  PresentationFontDescriptor(
    id: 'space-grotesk',
    family: 'Space Grotesk',
    description: 'Distinct geometric sans for product and technology decks',
    source: PresentationFontSource.googleFonts,
    roles: _bothRoles,
    weights: _regularWeights,
  ),
  PresentationFontDescriptor(
    id: 'lora',
    family: 'Lora',
    description: 'Contemporary serif with warm editorial character',
    source: PresentationFontSource.googleFonts,
    roles: _bothRoles,
    weights: _regularWeights,
  ),
  PresentationFontDescriptor(
    id: 'dm-sans',
    family: 'DM Sans',
    description: 'Friendly low-contrast sans for clear product communication',
    source: PresentationFontSource.googleFonts,
    roles: _bothRoles,
    weights: _regularWeights,
  ),
  PresentationFontDescriptor(
    id: 'montserrat',
    family: 'Montserrat',
    description: 'Confident geometric sans for professional headlines',
    source: PresentationFontSource.googleFonts,
    roles: _bothRoles,
    weights: _regularWeights,
  ),
  PresentationFontDescriptor(
    id: 'poppins',
    family: 'Poppins',
    description: 'Rounded geometric sans for approachable visual systems',
    source: PresentationFontSource.googleFonts,
    roles: _bothRoles,
    weights: _regularWeights,
  ),
  PresentationFontDescriptor(
    id: 'oswald',
    family: 'Oswald',
    description: 'Condensed display sans for strong, compact headlines',
    source: PresentationFontSource.googleFonts,
    roles: _headlineRole,
    weights: _regularWeights,
  ),
  PresentationFontDescriptor(
    id: 'lobster',
    family: 'Lobster',
    description: 'Expressive script reserved for playful display text',
    source: PresentationFontSource.googleFonts,
    roles: _headlineRole,
    weights: {400},
  ),
  PresentationFontDescriptor(
    id: 'open-sans',
    family: 'Open Sans',
    description: 'Humanist sans optimized for readable body copy',
    source: PresentationFontSource.googleFonts,
    roles: _bothRoles,
    weights: _regularWeights,
  ),
  PresentationFontDescriptor(
    id: 'lato',
    family: 'Lato',
    description: 'Warm professional sans with subtle personality',
    source: PresentationFontSource.googleFonts,
    roles: _bothRoles,
    weights: _regularWeights,
  ),
  PresentationFontDescriptor(
    id: 'source-serif-4',
    family: 'Source Serif 4',
    description: 'Readable variable serif for substantial body content',
    source: PresentationFontSource.googleFonts,
    roles: _bothRoles,
    weights: _regularWeights,
  ),
];
