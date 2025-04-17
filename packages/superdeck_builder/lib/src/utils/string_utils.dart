import 'dart:convert';

import 'package:superdeck_core/src/common/hash.dart'
    show generateValueHash;

/// Utility functions for string operations
class StringUtils {
  /// Private constructor to prevent instantiation
  StringUtils._();

  /// Converts a string to camelCase
  static String toCamelCase(String input) {
    if (input.isEmpty) return input;

    final words = input.split(RegExp(r'[_\s-]+'));

    if (words.isEmpty) return input;

    final firstWord = words[0].toLowerCase();
    final remainingWords = words.sublist(1).map(_capitalize).join('');

    return firstWord + remainingWords;
  }

  /// Converts a string to snake_case
  static String toSnakeCase(String input) {
    if (input.isEmpty) return input;

    // Replace spaces, hyphens with underscores
    var result = input.replaceAll(RegExp(r'[\s-]+'), '_');

    // Insert underscore before capital letters and convert to lowercase
    result = result.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );

    // Remove consecutive underscores and trim leading/trailing underscores
    result = result.replaceAll(RegExp(r'_+'), '_').trim();
    if (result.startsWith('_')) result = result.substring(1);

    return result.toLowerCase();
  }

  /// Capitalizes the first letter of a string
  static String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  /// Convert snake_case to PascalCase
  static String toPascalCase(String input) {
    final camelCase = toCamelCase(input);
    return camelCase.substring(0, 1).toUpperCase() + camelCase.substring(1);
  }

  /// Indent a string with a specified number of spaces
  static String indent(String input, {int spaces = 2}) {
    final indentation = ' ' * spaces;
    return input.split('\n').map((line) => '$indentation$line').join('\n');
  }
}

/// Generate a unique ID using timestamp and hash
String generateUniqueId({dynamic seed}) {
  final timestamp = DateTime.now().microsecondsSinceEpoch.toString();
  final hash = seed != null ? generateValueHash(seed.toString()) : '';
  return '$timestamp${hash.isNotEmpty ? '_$hash' : ''}';
}

/// Convert a string to base64
String toBase64(String input) {
  return base64Encode(utf8.encode(input));
}

/// Convert a base64 string back to a normal string
String fromBase64(String input) {
  return utf8.decode(base64Decode(input));
}
