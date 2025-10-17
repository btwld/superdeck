import 'dart:io';

import 'package:ack/ack.dart';

// List extensions
extension ListX<T> on List<T> {
  /// Returns a list of items that have been added and removed between this list and another
  ({List<T> added, List<T> removed}) compareWith(List<T> other) {
    final selfSet = toSet();
    final otherSet = other.toSet();

    return (
      added: other.where((item) => !selfSet.contains(item)).toList(),
      removed: where((item) => !otherSet.contains(item)).toList(),
    );
  }
}

// File extensions
extension FileExt on File {
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
extension DirectoryExt on Directory {
  /// Ensures a directory exists, creating it if necessary
  Future<Directory> ensureExists() async {
    if (!await exists()) {
      return await create(recursive: true);
    }
    return this;
  }
}

/// ACK (Schema Validation) helper function for enums
StringSchema ackEnum(List<Enum> values) {
  return Ack.string().enumString(
    values.map((e) {
      // Convert enum name to snake_case
      final name = e.name;
      return name
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAllMapped(
            RegExp(
              r'[A-Z]{2,}(?=[A-Z][a-z]+[0-9]*|\b)|[A-Z]?[a-z]+[0-9]*|[A-Z]|[0-9]+',
            ),
            (match) => "${match.group(0)!.toLowerCase()}_",
          )
          .replaceAll(RegExp(r'(_)\1+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
    }).toList(),
  );
}
