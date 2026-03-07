import 'package:superdeck_core/superdeck_core.dart';

import '../styling/styling.dart';
import 'slide_frame.dart';
import 'slide_template.dart';
import 'template_exception.dart';
import 'deck_theme.dart';

/// Result of resolving a slide's template and style configuration.
class TemplateResolutionResult {
  /// The fully merged style for the slide.
  final SlideStyle style;

  /// The slide frame (header, footer, background) for the slide.
  final SlideFrame frame;

  /// Whether a template was used in the resolution.
  final bool usingTemplate;

  const TemplateResolutionResult({
    required this.style,
    required this.frame,
    required this.usingTemplate,
  });
}

/// Resolves slide templates and styles from [DeckTheme].
///
/// Resolution order:
/// - **With template**: `defaultSlideStyle -> template.baseStyle -> template.styles[style]`
/// - **Without template**: `defaultSlideStyle -> theme.baseStyle -> theme.styles[style]`
/// - **With defaultTemplate**: applies when slide has no explicit template
class TemplateResolver {
  final DeckTheme _theme;

  TemplateResolver(this._theme) {
    if (_theme.templates.containsKey(noneTemplate)) {
      throw ArgumentError.value(
        noneTemplate,
        'templates',
        '"$noneTemplate" is reserved for opting out of defaultTemplate. '
            'Please use a different template name.',
      );
    }
  }

  /// Reserved template name that opts out of [DeckTheme.defaultTemplate].
  ///
  /// Use `template: 'none'` in slide options to fall back to deck-level
  /// styles even when a defaultTemplate is configured.
  static const noneTemplate = 'none';

  /// Resolves the style and parts for a slide based on its options.
  ///
  /// Throws [TemplateException] if:
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

      final template = _theme.templates[templateName];
      if (template == null) {
        final availableTemplates = _theme.templates.keys.toList();
        final availableMessage = availableTemplates.isEmpty
            ? 'No templates are registered in this deck.'
            : 'Available templates: ${availableTemplates.join(', ')}';

        throw TemplateException(
          'Unknown template "$templateName". $availableMessage',
        );
      }
      return template;
    }

    return _theme.defaultTemplate;
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
        throw TemplateException(
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
      frame: template.frame,
      usingTemplate: true,
    );
  }

  TemplateResolutionResult _resolveWithoutTemplate(String? styleName) {
    SlideStyle? styleOverride;
    if (styleName != null) {
      styleOverride = _theme.styles[styleName];
      if (styleOverride == null) {
        throw TemplateException(
          'Unknown style "$styleName" in deck. '
          'Available styles: ${_theme.styles.keys.join(', ')}',
        );
      }
    }

    final mergedStyle = defaultSlideStyle
        .merge(_theme.baseStyle)
        .merge(styleOverride);

    return TemplateResolutionResult(
      style: mergedStyle,
      frame: _theme.frame,
      usingTemplate: false,
    );
  }
}
