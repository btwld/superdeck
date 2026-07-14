/// Standardized context keys for the wizard workflow.
///
/// All catalog components should use these keys when writing to the
/// wizard context. This ensures consistent extraction in SummaryCard
/// and generation context building.
///
/// Usage:
/// ```dart
/// resolvedContext[WizardContextKeys.topic] = userTopic;
/// resolvedContext[WizardContextKeys.message] = displayMessage;
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

  /// Image style identifier (enum name).
  static const imageStyleId = 'imageStyleId';

  /// Image style display name.
  static const imageStyleName = 'imageStyleName';

  /// Image style description for generation guidance.
  static const imageStyleDescription = 'imageStyleDescription';

  // Common keys used across components

  /// Display message shown in chat bubble after selection.
  static const message = 'message';

  /// Generic title field for selections.
  static const title = 'title';

  /// Generic description field for selections.
  static const description = 'description';

  /// Selected options list (used by checkbox components).
  static const selectedOptions = 'selectedOptions';

  /// Maps normalized label strings to their context keys.
  ///
  /// Used by SummaryCard to extract context from AI-provided labels.
  /// Returns null for unrecognized labels.
  static String? labelToKey(String label) {
    final normalized = label.toLowerCase().trim();
    return _labelMap[normalized];
  }

  static const _labelMap = {
    // Topic variations
    'topic': topic,
    'presentation topic': topic,
    'subject': topic,
    // Audience variations
    'audience': audience,
    'target audience': audience,
    // Approach variations
    'approach': approach,
    'presentation approach': approach,
    'format': approach,
    // Emphasis variations
    'emphasis': emphasis,
    'emphases': emphasis,
    'key areas': emphasis,
    'focus areas': emphasis,
    // Slide count variations
    'slide count': slideCount,
    'slides': slideCount,
    'number of slides': slideCount,
    'total slides': slideCount,
    // Style variations
    'style': style,
    'visual style': style,
    'design style': style,
    'theme': style,
    // Image style variations
    'image style': imageStyleName,
    'visual direction': imageStyleName,
  };
}
