import 'dart:io';

import 'package:ack/ack.dart';

// File extensions
extension FileX on File {
  /// Ensures a file exists and optionally writes content to it
  Future<File> ensureExists({String? content}) async {
    if (!await exists()) {
      await create(recursive: true);
      if (content != null) {
        await writeAsString(content);
      }
    }
    return this;
  }

  /// Ensures that a file exists and writes the provided content to it
  Future<File> ensureWrite(String content) async {
    if (!await exists()) {
      await create(recursive: true);
    }
    return await writeAsString(content);
  }
}

// Directory extensions
extension DirectoryX on Directory {
  /// Ensures a directory exists, creating it if necessary
  Future<Directory> ensureExists() async {
    if (!await exists()) {
      return await create(recursive: true);
    }
    return this;
  }
}

/// ACK (Schema Validation) helper function for enums.
EnumSchema<T> ackEnum<T extends Enum>(List<T> values) {
  return Ack.enumValues(values);
}

/// Extension on StringSchema for hex color validation
extension HexColorValidation on StringSchema {
  /// Validates that the string is a valid hex color code.
  ///
  /// Supports:
  /// - 6 digit RGB: "#ff0000" or "ff0000"
  /// - 8 digit RGBA (with alpha): "#80ff0000" or "80ff0000"
  ///
  /// The '#' prefix is optional but recommended for clarity.
  ///
  /// Example:
  /// ```dart
  /// Ack.string().hexColor().nullable().optional()
  /// ```
  AckSchema<String> hexColor() {
    return refine(
      (value) {
        final hexCode = value.replaceAll('#', '');
        return (hexCode.length == 6 || hexCode.length == 8) &&
            RegExp(r'^[0-9a-fA-F]+$').hasMatch(hexCode);
      },
      message:
          'Invalid hex color. Use 6 or 8 hex digits (e.g., "#ff0000" or "#80ff0000")',
    );
  }
}
