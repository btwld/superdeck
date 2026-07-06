/// Predefined image styles for presentation generation.
///
/// AI selects from enum values, widget loads full metadata.
/// Each style shows the same subject in a different artistic treatment.
library;

/// Available image styles for presentation backgrounds.
///
/// Enhanced enum where:
/// - Enum value name = ID used in schema (e.g., `watercolor`, `flatDesign`)
/// - `title`: Display name for UI
/// - `description`: Short description for AI selection
/// - `treatment`: Full prompt treatment for image generation
enum ImageStyle {
  watercolor(
    title: 'Watercolor',
    description: 'Soft, artistic, dreamy - organic flowing shapes',
    treatment:
        'rendered in soft watercolor painting style with flowing '
        'organic shapes, gentle color bleeding between hues, and dreamy '
        'atmospheric quality. Muted pastel tones with subtle paper texture.',
  ),

  minimalist(
    title: 'Minimalist',
    description: 'Clean, modern, professional - geometric simplicity',
    treatment:
        'rendered in clean minimalist style with simple geometric '
        'shapes, generous negative space, and limited color palette. '
        'Modern and elegant with precise edges and balanced asymmetry.',
  ),

  gradient(
    title: 'Gradient',
    description: 'Dynamic, contemporary, vibrant - smooth color transitions',
    treatment:
        'rendered with smooth flowing gradients and rich color '
        'transitions blending seamlessly. Vibrant yet harmonious palette '
        'with subtle mesh effects creating depth and dimension.',
  ),

  retro(
    title: 'Retro',
    description: 'Nostalgic, playful, vintage - 60s/70s print aesthetic',
    treatment:
        'rendered in retro vintage illustration style with bold '
        'outlines, limited color palette reminiscent of 1960s-70s print. '
        'Halftone dots, warm muted colors, and slightly faded aesthetic.',
  ),

  geometric(
    title: 'Geometric',
    description: 'Technical, structured, bold - angular shapes and grids',
    treatment:
        'rendered as geometric abstract composition with clean '
        'angular shapes, precise lines, and structured grid-based layout. '
        'Bold primary colors with strong contrast and mathematical balance.',
  ),

  flatDesign(
    title: 'Flat Design',
    description: 'Friendly, approachable, corporate - simple vector style',
    treatment:
        'rendered in flat design illustration style with solid '
        'colors, no gradients or shadows, clean vector-like shapes. '
        'Simple, friendly, and approachable with bright cheerful palette.',
  );

  const ImageStyle({
    required this.title,
    required this.description,
    required this.treatment,
  });

  /// Display name shown to users (e.g., "Flat Design").
  final String title;

  /// Short description for AI selection guidance.
  final String description;

  /// Full art style treatment for image generation prompt.
  final String treatment;

  /// ID is the enum value name (e.g., "watercolor", "flatDesign").
  String get id => name;

  /// Builds a complete image generation prompt.
  ///
  /// Combines subject with style treatment:
  /// ```dart
  /// ImageStyle.watercolor.buildPrompt('runner crossing finish line');
  /// // → "Runner crossing finish line, rendered in soft watercolor..."
  /// ```
  String buildPrompt(String subject) {
    final capitalized = subject.isNotEmpty
        ? '${subject[0].toUpperCase()}${subject.substring(1)}'
        : subject;
    return '$capitalized, $treatment';
  }

  /// Finds a style by ID (enum name), returns null if not found.
  static ImageStyle? fromId(String id) {
    for (final style in values) {
      if (style.name == id) return style;
    }
    return null;
  }

  /// Cached options string for schema descriptions.
  static final _optionsDescription = values
      .map((s) => '${s.name} (${s.description})')
      .join(', ');

  /// Schema description with all styles and their descriptions.
  ///
  /// [count] specifies how many styles to select:
  /// - `count: 1` (default): "Image style. Choose one from: ..."
  /// - `count: 3`: "Select 3 styles from: ..."
  ///
  /// Throws [AssertionError] if count is less than 1 or greater than
  /// the number of available styles.
  static String schemaDescription({int count = 1}) {
    assert(
      count >= 1 && count <= values.length,
      'count must be between 1 and ${values.length}, got $count',
    );
    return count == 1
        ? 'Image style. Choose one from: $_optionsDescription.'
        : 'Select $count styles from: $_optionsDescription.';
  }
}
