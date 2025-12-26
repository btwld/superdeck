import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../deck/deck_options.dart';
import '../styles/slide_style.dart';
import 'style_schemas.dart';

final _logger = Logger('StyleConfig');

/// Function type for loading YAML content.
/// Returns the YAML string content, or null if not available.
typedef StyleYamlLoader = Future<String?> Function();

/// Loads, validates, and merges style configuration from YAML files with code-defined options.
///
/// This class combines YAML loading with style merging into a single, cohesive API.
/// It uses [StyleSchemas.styleConfigSchema] which validates and transforms YAML
/// directly into [StyleConfiguration] with Flutter types.
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
///   // Load styles.yaml and merge with code options
///   final options = await StyleConfig.loadAndMerge(
///     DeckOptions(
///       baseStyle: myCustomStyle,
///       styles: {'special': specialStyle},
///     ),
///   );
///
///   runApp(SuperDeckApp(options: options));
/// }
/// ```
class StyleConfig {
  StyleConfig._();

  /// Default styles file path relative to working directory.
  static const defaultStylesPath = 'styles.yaml';

  // ===========================================================================
  // PUBLIC API
  // ===========================================================================

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
    final yamlConfig = await _load(
      path: stylesPath ?? defaultStylesPath,
      loader: loader,
    );

    if (yamlConfig == null) {
      _logger.fine('No YAML style configuration loaded, using code options only');
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
    final mergedBaseStyle = _mergeBaseStyle(
      yamlConfig.baseStyle,
      codeOptions.baseStyle,
    );

    final mergedStyles = _mergeStyleMaps(
      yamlConfig.styles,
      codeOptions.styles,
    );

    return codeOptions.copyWith(
      baseStyle: mergedBaseStyle,
      styles: mergedStyles,
    );
  }

  // ===========================================================================
  // YAML LOADING (Private)
  // ===========================================================================

  /// Loads style configuration from a YAML file or injected loader.
  ///
  /// Parameters:
  /// - [loader]: Optional custom loader function. If provided, it will be used
  ///   instead of file loading. Useful for web platforms or testing.
  /// - [path]: File path to load from.
  ///
  /// Returns null if:
  /// - The loader returns null
  /// - The file doesn't exist (when using default file loader)
  /// - Running on web without a custom loader
  /// - The YAML is invalid or validation fails
  static Future<StyleConfiguration?> _load({
    StyleYamlLoader? loader,
    required String path,
  }) async {
    final resolvedLoader = loader ?? () => _defaultFileLoader(path);
    final yamlString = await resolvedLoader();

    if (yamlString == null) return null;

    return _fromYamlString(yamlString);
  }

  /// Parses and validates a YAML string into a [StyleConfiguration].
  ///
  /// The schema validates the YAML structure and transforms it directly
  /// into Flutter/Mix types using Ack's transform() method.
  ///
  /// Returns null if:
  /// - The YAML string is empty or invalid
  /// - Validation fails against the style schema
  static StyleConfiguration? _fromYamlString(String yamlString) {
    final content = yamlString.trim();
    if (content.isEmpty) return null;

    final Map<String, dynamic> map;
    try {
      map = convertYamlToMap(content, strict: true);
    } catch (e) {
      _logger.warning('Failed to parse YAML: $e');
      return null;
    }

    if (map.isEmpty) return null;

    final result = StyleSchemas.styleConfigSchema.safeParse(map);
    if (result.isFail) {
      final error = result.getError();
      _logger.warning('Style configuration validation failed: ${error.message}');
      return null;
    }

    return result.getOrThrow();
  }

  /// Default file loader using dart:io.
  ///
  /// Returns null on web platforms or if the file doesn't exist.
  static Future<String?> _defaultFileLoader(String path) async {
    if (kIsWeb) {
      _logger.info(
        'Style file loading not available on web. '
        'Use a custom loader or provide styles in code.',
      );
      return null;
    }

    final file = File(path);
    if (!await file.exists()) {
      _logger.fine('Style file not found at: $path');
      return null;
    }

    try {
      return await file.readAsString();
    } catch (e) {
      _logger.warning('Failed to read style file at $path: $e');
      return null;
    }
  }

  // ===========================================================================
  // STYLE MERGING (Private)
  // ===========================================================================

  /// Merges base styles with correct precedence.
  ///
  /// Returns:
  /// - null if both are null
  /// - yaml style if code is null
  /// - code style if yaml is null
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
