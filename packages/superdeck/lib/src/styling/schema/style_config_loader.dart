import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:superdeck_core/superdeck_core.dart';

import 'style_schemas.dart';

final _logger = Logger('StyleConfigLoader');

/// Function type for loading YAML content.
/// Returns the YAML string content, or null if not available.
typedef StyleYamlLoader = Future<String?> Function();

/// Loads and validates style configuration from YAML files.
///
/// This loader uses [StyleSchemas.styleConfigSchema] which validates
/// and transforms YAML directly into [StyleConfiguration] with Flutter types.
///
/// ## Usage
///
/// ```dart
/// // Default path (styles.yaml)
/// final config = await StyleConfigLoader.load();
///
/// // Custom path
/// final config = await StyleConfigLoader.load(path: 'themes/dark.yaml');
///
/// // Injected loader (web/testing)
/// final config = await StyleConfigLoader.load(
///   loader: () async => myYamlString,
/// );
/// ```
class StyleConfigLoader {
  StyleConfigLoader._();

  /// Default styles file path relative to working directory.
  static const defaultStylesPath = 'styles.yaml';

  /// Parses and validates a YAML string into a [StyleConfiguration].
  ///
  /// The schema validates the YAML structure and transforms it directly
  /// into Flutter/Mix types using Ack's transform() method.
  ///
  /// Returns null if:
  /// - The YAML string is empty or invalid
  /// - Validation fails against the style schema
  static StyleConfiguration? fromYamlString(String yamlString) {
    final content = yamlString.trim();
    if (content.isEmpty) return null;

    // Use convertYamlToMap from superdeck_core (no new dependency)
    final Map<String, dynamic> map;
    try {
      map = convertYamlToMap(content, strict: true);
    } catch (e) {
      _logger.warning('Failed to parse YAML: $e');
      return null;
    }

    if (map.isEmpty) return null;

    // Schema validates AND transforms to StyleConfiguration in one step
    final result = StyleSchemas.styleConfigSchema.safeParse(map);
    if (result.isFail) {
      final error = result.getError();
      _logger.warning('Style configuration validation failed: ${error.message}');
      return null;
    }

    // result.getOrThrow() returns StyleConfiguration directly due to transform()
    return result.getOrThrow();
  }

  /// Loads style configuration from a YAML file or injected loader.
  ///
  /// Parameters:
  /// - [loader]: Optional custom loader function. If provided, it will be used
  ///   instead of file loading. Useful for web platforms or testing.
  /// - [path]: File path to load from. Defaults to [defaultStylesPath].
  ///
  /// Returns null if:
  /// - The loader returns null
  /// - The file doesn't exist (when using default file loader)
  /// - Running on web without a custom loader
  /// - The YAML is invalid or validation fails
  static Future<StyleConfiguration?> load({
    StyleYamlLoader? loader,
    String path = defaultStylesPath,
  }) async {
    final resolvedLoader = loader ?? () => _defaultFileLoader(path);
    final yamlString = await resolvedLoader();

    if (yamlString == null) return null;

    return fromYamlString(yamlString);
  }

  /// Default file loader using dart:io.
  ///
  /// Returns null on web platforms or if the file doesn't exist.
  static Future<String?> _defaultFileLoader(String path) async {
    // dart:io is not available on web
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
}
