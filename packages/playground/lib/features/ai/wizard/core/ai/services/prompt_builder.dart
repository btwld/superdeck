import '../wizard_context.dart';

/// Builds a deck generation prompt from wizard context data.
///
/// Extracts user selections from the 8-step wizard workflow and formats
/// them into a structured prompt for the AI generation service.
String buildPromptFromWizardContext(WizardContext context) {
  final buffer = StringBuffer();

  buffer.writeln('Generate a presentation with the following specifications:');
  buffer.writeln();

  _writeBasicFields(buffer, context);
  _writeColorPalette(buffer, context);
  _writeFontConfiguration(buffer, context);
  _writeImageStyleDirection(buffer, context);
  _writeLayoutGuidance(buffer);

  return buffer.toString();
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

void _writeBasicFields(StringBuffer buffer, WizardContext context) {
  if (context.topic != null) {
    buffer.writeln('Topic: ${_sanitize(context.topic)}');
  }
  if (context.audience != null) {
    buffer.writeln('Target Audience: ${_sanitize(context.audience)}');
  }
  if (context.approach != null) {
    buffer.writeln('Presentation Approach: ${_sanitize(context.approach)}');
  }
  if (context.emphasis != null && context.emphasis!.isNotEmpty) {
    final sanitized = context.emphasis!.map((e) => _sanitize(e)).join(', ');
    buffer.writeln('Key Areas to Emphasize: $sanitized');
  }
  if (context.slideCount != null) {
    final count = context.slideCount!;
    if (count > 0 && count <= 50) {
      buffer.writeln('Number of Slides: $count');
    }
  }
  if (context.style != null) {
    buffer.writeln('Visual Style: ${_sanitize(context.style)}');
  }
}

void _writeColorPalette(StringBuffer buffer, WizardContext context) {
  final colors = context.colors;
  if (colors != null && colors.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('Color Palette:');
    buffer.writeln('  - Background: ${_sanitize(colors[0])}');
    if (colors.length > 1) {
      buffer.writeln('  - Heading text: ${_sanitize(colors[1])}');
    }
    if (colors.length > 2) {
      buffer.writeln('  - Body text: ${_sanitize(colors[2])}');
    }
  }
}

void _writeFontConfiguration(StringBuffer buffer, WizardContext context) {
  if (context.headlineFont != null) {
    buffer.writeln('Headline Font: ${_sanitize(context.headlineFont)}');
  }
  if (context.bodyFont != null) {
    buffer.writeln('Body Font: ${_sanitize(context.bodyFont)}');
  }
}

void _writeImageStyleDirection(StringBuffer buffer, WizardContext context) {
  if (context.imageStyleName != null) {
    buffer.writeln();
    buffer.writeln('Visual Direction: ${_sanitize(context.imageStyleName)}');
    if (context.imageStyleDescription != null) {
      buffer.writeln(
        'Visual Style Description: ${_sanitize(context.imageStyleDescription)}',
      );
    }
  }
}

void _writeLayoutGuidance(StringBuffer buffer) {
  buffer.writeln();
  buffer.writeln(
    'Layout Guidance: Use sections as rows and blocks as columns. Use 1-2 '
    'blocks per section (never 4+). Put all bullets in a single block. Use '
    'two sections (title + body) for most slides. Center-align only titles; '
    'left-align body content. Do not use widget blocks or empty blocks. '
    'Keep slide titles short (3-5 words max) to prevent text cutoff; use '
    'smaller heading sizes (### or ####) for longer titles.',
  );
}
