import 'package:superdeck_core/superdeck_core.dart';

import '../rendering/slides/slide_parts.dart';
import '../styling/components/slide.dart';
import '../styling/default_style.dart';
import 'deck_options.dart';
import 'slide_template.dart';

/// Result of resolving a slide's template and style configuration.
class TemplateResolutionResult {
  /// The fully merged style for the slide.
  final SlideStyle style;

  /// The chrome parts (header, footer, background) for the slide.
  final SlideParts parts;

  /// Whether a template was used in the resolution.
  final bool usingTemplate; // ignore: unused-code

  const TemplateResolutionResult({
    required this.style,
    required this.parts,
    required this.usingTemplate,
  });
}

/// Resolves slide templates and styles from [DeckOptions].
///
/// Resolution order:
/// - **With template**: `defaultSlideStyle -> template.baseStyle -> template.styles[style]`
/// - **Without template**: `defaultSlideStyle -> options.baseStyle -> options.styles[style]`
/// - **With defaultTemplate**: applies when slide has no explicit template
class TemplateResolver {
  final DeckOptions _options;

  TemplateResolver(this._options) {
    if (_options.templates.containsKey(noneTemplate)) {
      throw ArgumentError.value(
        noneTemplate,
        'templates',
        '"$noneTemplate" is reserved for opting out of defaultTemplate. '
            'Please use a different template name.',
      );
    }
  }

  /// Reserved template name that opts out of [DeckOptions.defaultTemplate].
  ///
  /// Use `template: 'none'` in slide options to fall back to deck-level
  /// styles even when a defaultTemplate is configured.
  static const noneTemplate = 'none';

  /// Resolves the style and parts for a slide based on its options.
  ///
  /// Throws [ArgumentError] if:
  /// - The slide references an unknown template name
  /// - The slide references an unknown style within a template
  /// - The slide references an unknown deck-level style (when not using a template)
  TemplateResolutionResult resolve(SlideOptions? slideOptions) {
    final templateName = slideOptions?.template;
    final styleName = slideOptions?.style;

    // Determine which template to use (explicit > default > none)
    final template = _resolveTemplate(templateName);

    if (template != null) {
      return _resolveWithTemplate(
        template,
        templateName ?? 'defaultTemplate',
        styleName,
      );
    }

    return _resolveWithoutTemplate(styleName);
  }

  SlideTemplate? _resolveTemplate(String? templateName) {
    if (templateName != null) {
      // 'none' explicitly opts out of any template
      if (templateName == noneTemplate) return null;

      final template = _options.templates[templateName];
      if (template == null) {
        final availableTemplates = _options.templates.keys.toList();
        final availableMessage = availableTemplates.isEmpty
            ? 'No templates are registered in this deck.'
            : 'Available templates: ${availableTemplates.join(', ')}';

        throw ArgumentError(
          'Unknown template "$templateName". $availableMessage',
        );
      }
      return template;
    }

    return _options.defaultTemplate;
  }

  TemplateResolutionResult _resolveWithTemplate(
    SlideTemplate template,
    String templateName,
    String? styleName,
  ) {
    SlideStyle? styleOverride;
    if (styleName != null) {
      styleOverride = template.styles[styleName];
      if (styleOverride == null) {
        throw ArgumentError(
          'Unknown style "$styleName" in template "$templateName". '
          'Available styles: ${template.styles.keys.join(', ')}',
        );
      }
    }

    final mergedStyle = defaultSlideStyle
        .merge(template.baseStyle)
        .merge(styleOverride);

    return TemplateResolutionResult(
      style: mergedStyle,
      parts: template.parts,
      usingTemplate: true,
    );
  }

  TemplateResolutionResult _resolveWithoutTemplate(String? styleName) {
    SlideStyle? styleOverride;
    if (styleName != null) {
      styleOverride = _options.styles[styleName];
      if (styleOverride == null) {
        throw ArgumentError(
          'Unknown style "$styleName" in deck. '
          'Available styles: ${_options.styles.keys.join(', ')}',
        );
      }
    }

    final mergedStyle = defaultSlideStyle
        .merge(_options.baseStyle)
        .merge(styleOverride);

    return TemplateResolutionResult(
      style: mergedStyle,
      parts: _options.parts,
      usingTemplate: false,
    );
  }
}
