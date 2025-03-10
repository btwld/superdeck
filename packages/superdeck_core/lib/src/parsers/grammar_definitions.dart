import 'dart:math' as math;

import 'base_parser.dart';

/// Parser for string options with improved structure and error handling
class StringOptionsParser extends BaseParser {
  const StringOptionsParser();

  /// Parse the input string into a map of options
  Map<String, dynamic> _parseInput(String input) {
    final trimmedInput = input.trim();
    if (trimmedInput.isEmpty) {
      return {};
    }

    final Map<String, dynamic> result = {};
    final List<String> expressions = _splitByDelimiter(trimmedInput, ' ');

    for (final expression in expressions) {
      try {
        final MapEntry<String, dynamic> entry = _parseExpression(expression);
        result[entry.key] = entry.value;
      } catch (e) {
        // Skip invalid expressions
        continue;
      }
    }

    return result;
  }

  /// Parse a single expression like "key=value" or "key"
  MapEntry<String, dynamic> _parseExpression(String expression) {
    final equalIndex = expression.indexOf('=');

    if (equalIndex == -1) {
      // No value provided, default to true
      return MapEntry(expression.trim(), true);
    }

    final key = expression.substring(0, equalIndex).trim();
    final valueStr = expression.substring(equalIndex + 1).trim();

    // Validate key is not empty
    if (key.isEmpty) {
      throw FormatException('Empty key in expression: $expression');
    }

    return MapEntry(key, _parseValue(valueStr));
  }

  /// Parse a value which could be a string, number, boolean, or list
  Object _parseValue(String value) {
    // Handle empty value
    if (value.isEmpty) return '';

    // Check if it's a quoted string
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      return value.substring(1, value.length - 1);
    }

    // Check if it's a list
    if (value.startsWith('[') && value.endsWith(']')) {
      return _parseList(value);
    }

    // Check if it's a boolean
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;

    // Check if it's a number
    if (_isNumeric(value)) {
      return value.contains('.') ? double.parse(value) : int.parse(value);
    }

    // Default to string
    return value;
  }

  /// Parse a list value like [1, 2, 3] or ["a", "b", "c"]
  List<Object> _parseList(String value) {
    // Remove brackets
    final listContent = value.substring(1, value.length - 1).trim();
    if (listContent.isEmpty) return [];

    // Split into list items
    final items = _splitByDelimiter(listContent, ',');
    final Set<Object> uniqueItems = {}; // Track unique items

    for (final item in items) {
      final trimmedItem = item.trim();
      if (trimmedItem.isEmpty) continue;

      // Check for number range (e.g., "2-5")
      final rangeMatch = RegExp(r'^(\d+)-(\d+)$').firstMatch(trimmedItem);
      if (rangeMatch != null) {
        final start = int.parse(rangeMatch.group(1)!);
        final end = int.parse(rangeMatch.group(2)!);

        if (start > end) {
          throw FormatException('Invalid range: $start-$end');
        }

        for (int i = start; i <= end; i++) {
          uniqueItems.add(i);
        }
        continue;
      }

      // Parse as regular value
      uniqueItems.add(_parseValue(trimmedItem));
    }

    return uniqueItems.toList();
  }

  /// Split a string by delimiter, respecting quotes and brackets
  /// This unified method replaces both _splitExpressions and _splitListItems
  List<String> _splitByDelimiter(String input, String delimiter) {
    final List<String> result = [];

    bool inQuotes = false;
    int bracketDepth = 0;
    String quoteChar = '';
    int start = 0;

    for (int i = 0; i < input.length; i++) {
      final char = input[i];

      // Handle quotes (both single and double)
      if ((char == '"' || char == "'") &&
          (inQuotes == false || quoteChar == char)) {
        inQuotes = !inQuotes;
        quoteChar = inQuotes ? char : '';
      }
      // Handle nested brackets
      else if (char == '[' && !inQuotes) {
        bracketDepth++;
      } else if (char == ']' && !inQuotes) {
        bracketDepth = math.max(0, bracketDepth - 1); // Avoid negative depth
      }
      // Split on delimiter only when not in quotes or brackets
      else if (char == delimiter && !inQuotes && bracketDepth == 0) {
        if (i > start) {
          result.add(input.substring(start, i));
        }
        start = i + 1;
      }
    }

    // Add the last segment
    if (start < input.length) {
      result.add(input.substring(start));
    }

    return result;
  }

  /// Check if a string is a valid number
  bool _isNumeric(String value) {
    return RegExp(r'^-?\d+(\.\d+)?$').hasMatch(value);
  }

  /// Parse a string of options into a ParseResult
  @override
  ParseResult parse(String input) {
    return ParseResult(_parseInput(input));
  }
}

/// Result of parsing string options
class ParseResult {
  final Map<String, dynamic> value;

  const ParseResult(this.value);
}
