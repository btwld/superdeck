import '../../deck/deck_options.dart';
import '../slide_style.dart';
import 'style_config_loader.dart';
import 'style_schemas.dart';

/// Merges style configuration from YAML files with code-defined options.
///
/// ## Merge Precedence
/// Code styles win over YAML styles. The merge order is:
/// 1. Start with YAML configuration (if present)
/// 2. Merge code configuration on top (code wins conflicts)
///
/// This means:
/// - If YAML defines a property and code doesn't: YAML value is used
/// - If code defines a property and YAML doesn't: code value is used
/// - If both define a property: code value wins
///
/// ## Usage
///
/// ```dart
/// void main() async {
///   final options = await StyleOptionsMerger.loadAndMerge(
///     DeckOptions(
///       baseStyle: myCustomStyle,
///       styles: {'special': specialStyle},
///     ),
///   );
///
///   runApp(SuperDeckApp(options: options));
/// }
/// ```
class StyleOptionsMerger {
  StyleOptionsMerger._();

  /// Loads YAML configuration and merges it with code-defined options.
  ///
  /// Parameters:
  /// - [codeOptions]: The code-defined DeckOptions (always preserved)
  /// - [stylesPath]: Optional custom path to styles.yaml file
  /// - [loader]: Optional custom loader for web/testing
  ///
  /// Returns [codeOptions] unchanged if:
  /// - No YAML file is found
  /// - YAML parsing fails
  /// - Running on web without a custom loader
  static Future<DeckOptions> loadAndMerge(
    DeckOptions codeOptions, {
    String? stylesPath,
    StyleYamlLoader? loader,
  }) async {
    final yamlConfig = await StyleConfigLoader.load(
      path: stylesPath ?? StyleConfigLoader.defaultStylesPath,
      loader: loader,
    );

    if (yamlConfig == null) {
      // No YAML config found or parsing failed - return code options unchanged
      return codeOptions;
    }

    return merge(yamlConfig, codeOptions);
  }

  /// Merges YAML configuration with code options.
  ///
  /// Code options take precedence over YAML options.
  static DeckOptions merge(
    StyleConfiguration yamlConfig,
    DeckOptions codeOptions,
  ) {
    // Merge baseStyle: yaml?.merge(code) ?? code
    final mergedBaseStyle = _mergeBaseStyle(
      yamlConfig.baseStyle,
      codeOptions.baseStyle,
    );

    // Merge styles map
    final mergedStyles = _mergeStyleMaps(
      yamlConfig.styles,
      codeOptions.styles,
    );

    return codeOptions.copyWith(
      baseStyle: mergedBaseStyle,
      styles: mergedStyles,
    );
  }

  /// Merges base styles with correct precedence.
  ///
  /// Returns:
  /// - null if both are null
  /// - yaml style if code is null
  /// - yaml merged with code (code wins) if both exist
  static SlideStyle? _mergeBaseStyle(
    SlideStyle? yamlStyle,
    SlideStyle? codeStyle,
  ) {
    if (codeStyle == null) return yamlStyle;
    return yamlStyle?.merge(codeStyle) ?? codeStyle;
  }

  /// Merges style maps with correct precedence.
  ///
  /// For each style name:
  /// - If only in yaml: use yaml style
  /// - If only in code: use code style
  /// - If in both: merge yaml with code (code wins)
  static Map<String, SlideStyle> _mergeStyleMaps(
    Map<String, SlideStyle> yamlStyles,
    Map<String, SlideStyle> codeStyles,
  ) {
    return {
      ...yamlStyles,
      for (final MapEntry(:key, :value) in codeStyles.entries)
        key: _mergeWithCode(yamlStyles[key], value),
    };
  }

  static SlideStyle _mergeWithCode(SlideStyle? yamlStyle, SlideStyle codeStyle) {
    return yamlStyle?.merge(codeStyle) ?? codeStyle;
  }
}
