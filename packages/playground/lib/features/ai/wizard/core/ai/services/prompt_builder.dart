import '../../../../../../core/domain/design/presentation_image_style_catalog.dart';
import '../../../../quick_agent/core/engine/services/deck_generation_request.dart';
import '../wizard_context.dart';

/// Builds a deck generation prompt from wizard context data.
///
/// Extracts exact user selections from the Wizard workflow without
/// flattening contractual fields into layout instructions.
DeckGenerationRequest buildPromptFromWizardContext(
  WizardContext context, {
  PresentationImageStyleCatalog? imageStyleCatalog,
}) {
  final request = DeckGenerationRequest(
    userIntent: _sanitize(context.topic).isEmpty
        ? 'Create a coherent presentation.'
        : _sanitize(context.topic),
    slideCount: _wizardSlideCount(context.slideCount),
    audience: _sanitizedOrNull(context.audience),
    approach: _sanitizedOrNull(context.approach),
    emphasis:
        context.emphasis
            ?.map(_sanitize)
            .where((item) => item.isNotEmpty)
            .toList() ??
        const [],
    themeId: _sanitizedOrNull(context.themeId),
    designDirection: _sanitizedOrNull(context.style),
    density: _sanitizedOrNull(context.density),
    colors:
        context.colors
            ?.map(_sanitize)
            .where((item) => item.isNotEmpty)
            .toList() ??
        const [],
    headlineFont: _sanitizedOrNull(context.headlineFont),
    bodyFont: _sanitizedOrNull(context.bodyFont),
    imageStyleId: _sanitizedOrNull(context.imageStyleId),
    imageStyleVersion: context.imageStyleVersion,
  );
  request.resolveImageStyle(
    imageStyleCatalog ?? PresentationImageStyleCatalog.withDefaults(),
  );

  return request;
}

/// Maximum length for user-provided text fields.
const int _maxFieldLength = 500;

/// Sanitizes user input to prevent prompt injection.
///
/// - Truncates to max length
/// - Flattens newlines/tabs so a field cannot create forged prompt sections
/// - Removes remaining control characters
String _sanitize(Object? value) {
  if (value == null) return '';
  var text = value.toString();

  // Truncate to prevent excessive input
  if (text.length > _maxFieldLength) {
    text = '${text.substring(0, _maxFieldLength)}...';
  }

  text = text.replaceAll(RegExp(r'[\r\n\t]+'), ' ');
  text = text.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
  text = text.replaceAll(RegExp(' {2,}'), ' ').trim();

  return text;
}

String? _sanitizedOrNull(Object? value) {
  final sanitized = _sanitize(value);
  return sanitized.isEmpty ? null : sanitized;
}

int _wizardSlideCount(int? value) {
  if (value == null || value < 5 || value > 20) return 10;
  return value;
}
