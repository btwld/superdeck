import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';

/// Writes a JSON reference file, preserving the timestamp when content unchanged.
///
/// [file] - The output file to write
/// [reference] - The reference map to serialize (should have a 'metadata' key)
/// [buildMetadata] - Function to build the metadata map (receives the timestamp)
///
/// Returns true if the file was written, false if unchanged.
bool writeJsonIfChanged({
  required File file,
  required Map<String, dynamic> reference,
  required Map<String, dynamic> Function(String timestamp) buildMetadata,
}) {
  final existing = file.existsSync()
      ? jsonDecode(file.readAsStringSync()) as Map<String, dynamic>
      : null;

  final previousTimestamp =
      (existing?['metadata'] as Map<String, dynamic>?)?['generated'] as String?;

  // Prime metadata (with prior timestamp if available) so comparisons include
  // all metadata fields except the timestamp itself.
  final referenceWithMetadata = Map<String, dynamic>.from(reference)
    ..['metadata'] = buildMetadata(previousTimestamp ?? '');

  // Compare content without the 'generated' field
  final hasChanges = !_contentEquals(referenceWithMetadata, existing);

  final timestamp = hasChanges || previousTimestamp == null
      ? DateTime.now().toIso8601String()
      : previousTimestamp;

  // Now set the metadata with the final timestamp
  reference['metadata'] = buildMetadata(timestamp);

  final content = const JsonEncoder.withIndent('  ').convert(reference);
  final shouldWrite = !file.existsSync() || file.readAsStringSync() != content;

  if (shouldWrite) {
    file.writeAsStringSync(content);
    return true;
  }
  return false;
}

/// Compares two reference maps, ignoring the 'generated' field in metadata.
bool _contentEquals(
  Map<String, dynamic> next,
  Map<String, dynamic>? existing,
) {
  if (existing == null) return false;

  // Shallow copy to avoid mutating originals
  final nextCopy = Map<String, dynamic>.from(next);
  final existingCopy = Map<String, dynamic>.from(existing);

  // Remove generated field from metadata for comparison
  final nextMeta = nextCopy['metadata'];
  final existingMeta = existingCopy['metadata'];

  if (nextMeta is Map<String, dynamic>) {
    nextCopy['metadata'] = Map<String, dynamic>.from(nextMeta)
      ..remove('generated');
  }
  if (existingMeta is Map<String, dynamic>) {
    existingCopy['metadata'] = Map<String, dynamic>.from(existingMeta)
      ..remove('generated');
  }

  return const DeepCollectionEquality().equals(nextCopy, existingCopy);
}
