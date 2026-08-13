/// Standardized context keys for the wizard workflow.
///
/// All catalog components should use these keys when writing to the
/// wizard context. This keeps generation context building consistent.
///
/// Usage:
/// ```dart
/// resolvedContext[WizardContextKeys.topic] = userTopic;
/// ```
abstract final class WizardContextKeys {
  // Core wizard step keys

  /// The presentation topic entered by the user.
  static const topic = 'topic';

  /// The target audience selection.
  static const audience = 'audience';

  /// The presentation approach/format selection.
  static const approach = 'approach';

  /// The emphasis areas (multi-select topics).
  static const emphasis = 'emphasis';

  /// The number of slides selected.
  static const slideCount = 'slideCount';

  /// The visual style name.
  static const style = 'style';

  /// Stable ID of the selected presentation theme.
  static const themeId = 'themeId';

  /// Optional preferred content-density profile.
  static const density = 'density';

  // Style-related keys

  /// Color palette as list of hex strings.
  static const colors = 'colors';

  /// Headline/title font identifier.
  static const headlineFont = 'headlineFont';

  /// Body text font identifier.
  static const bodyFont = 'bodyFont';

  // Image style keys

  /// Stable image-style catalog ID.
  static const imageStyleId = 'imageStyleId';

  /// Exact version paired with [imageStyleId].
  static const imageStyleVersion = 'imageStyleVersion';

  // Common keys used across components

  /// Generic title field for selections.
  static const title = 'title';

  /// Generic description field for selections.
  static const description = 'description';
}
