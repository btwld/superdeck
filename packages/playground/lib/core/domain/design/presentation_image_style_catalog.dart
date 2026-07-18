/// Stable preview trio generated as soon as the Wizard accepts a topic.
const featuredPresentationImageStyleIds = [
  'minimalist',
  'watercolor',
  'gradient',
];

/// One described, versioned image treatment available to deck generation.
final class PresentationImageStyleDescriptor {
  final String id;

  final int version;
  final String title;
  final String description;
  final String treatment;
  const PresentationImageStyleDescriptor({
    required this.id,
    required this.version,
    required this.title,
    required this.description,
    required this.treatment,
  });

  /// Combines a concrete subject with this locally owned treatment.
  String buildPrompt(String subject) {
    final normalized = subject.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(subject, 'subject', 'Must not be empty.');
    }
    final capitalized =
        '${normalized[0].toUpperCase()}${normalized.substring(1)}';

    return '$capitalized, $treatment';
  }
}

/// Injectable registry and exact-version resolver for image treatments.
final class PresentationImageStyleCatalog {
  final List<PresentationImageStyleDescriptor> styles;

  final Map<String, PresentationImageStyleDescriptor> _byVersion = {};

  final Map<String, PresentationImageStyleDescriptor> _currentById = {};
  PresentationImageStyleCatalog(
    Iterable<PresentationImageStyleDescriptor> styles,
  ) : styles = List.unmodifiable(styles) {
    if (this.styles.isEmpty) {
      throw ArgumentError('Presentation image style catalog cannot be empty.');
    }
    for (final style in this.styles) {
      _validateDescriptor(style);
      final versionKey = _versionKey(style.id, style.version);
      if (_byVersion.containsKey(versionKey)) {
        throw ArgumentError(
          'Duplicate presentation image style reference "$versionKey".',
        );
      }
      _byVersion[versionKey] = style;
      final current = _currentById[style.id];
      if (current == null || current.version < style.version) {
        _currentById[style.id] = style;
      }
    }
  }
  factory PresentationImageStyleCatalog.withDefaults() =>
      defaultPresentationImageStyleCatalog;

  PresentationImageStyleDescriptor? current(String id) =>
      _currentById[id.trim()];

  /// Resolves one exact image-style ID and version.
  PresentationImageStyleDescriptor resolve({
    required String id,
    required int version,
  }) {
    final descriptor = _byVersion[_versionKey(id, version)];
    if (descriptor != null) return descriptor;

    final currentVersion = current(id)?.version;
    final detail = currentVersion == null
        ? 'The image style ID is unknown.'
        : 'Current catalog version is $currentVersion.';
    throw ArgumentError(
      'Unknown or stale presentation image style "$id@$version". $detail',
    );
  }
}

void _validateDescriptor(PresentationImageStyleDescriptor style) {
  if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(style.id)) {
    throw ArgumentError('Image style ID "${style.id}" must use kebab-case.');
  }
  if (style.version < 1) {
    throw ArgumentError(
      'Image style "${style.id}" must have a positive version.',
    );
  }
  if (style.title.trim().isEmpty ||
      style.description.trim().isEmpty ||
      style.treatment.trim().isEmpty) {
    throw ArgumentError(
      'Image style "${style.id}" requires a title, description, and treatment.',
    );
  }
}

String _versionKey(String id, int version) => '${id.trim()}@$version';

final defaultPresentationImageStyleCatalog = PresentationImageStyleCatalog(
  const [
    PresentationImageStyleDescriptor(
      id: 'watercolor',
      version: 1,
      title: 'Watercolor',
      description: 'Soft, expressive artwork with organic painted texture',
      treatment:
          'rendered in a soft watercolor painting style with flowing organic '
          'shapes, gentle color bleeding, muted pastel tones, and subtle paper '
          'texture',
    ),
    PresentationImageStyleDescriptor(
      id: 'minimalist',
      version: 1,
      title: 'Minimalist',
      description: 'Clean, modern artwork with precise geometric simplicity',
      treatment:
          'rendered in a clean minimalist style with simple geometric shapes, '
          'generous negative space, a limited color palette, precise edges, '
          'and balanced asymmetry',
    ),
    PresentationImageStyleDescriptor(
      id: 'gradient',
      version: 1,
      title: 'Gradient',
      description: 'Dynamic contemporary artwork with rich color transitions',
      treatment:
          'rendered with smooth flowing gradients and rich color transitions, '
          'a vibrant harmonious palette, and subtle mesh effects that create '
          'depth and dimension',
    ),
    PresentationImageStyleDescriptor(
      id: 'retro',
      version: 1,
      title: 'Retro',
      description: 'Playful artwork with a warm 1960s and 1970s print feel',
      treatment:
          'rendered in a retro print illustration style with bold outlines, '
          'halftone dots, warm muted colors, and a lightly faded finish',
    ),
    PresentationImageStyleDescriptor(
      id: 'geometric',
      version: 1,
      title: 'Geometric',
      description: 'Structured technical artwork using angular forms and grids',
      treatment:
          'rendered as a geometric abstract composition with clean angular '
          'shapes, precise lines, a structured grid, bold contrast, and '
          'mathematical balance',
    ),
    PresentationImageStyleDescriptor(
      id: 'flat-design',
      version: 1,
      title: 'Flat Design',
      description: 'Friendly approachable artwork using simple vector forms',
      treatment:
          'rendered as a flat vector illustration with solid colors, clean '
          'shapes, simple forms, no gradients, and an approachable palette',
    ),
  ],
);
