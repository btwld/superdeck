import 'dart:io';

import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:path/path.dart' as p;

part 'deck_workspace.ack.dart';
part 'deck_workspace.g.dart';

StringSchema _safeWorkspacePathSchema() => Ack.string().refine(
  _isRelativeWithoutTraversal,
  message:
      'must be a relative path without ".." traversal segments'
      ' (absolute paths and parent-directory traversal are not allowed)',
);

bool _isRelativeWithoutTraversal(String value) {
  if (p.isAbsolute(value)) return false;
  return !p.split(value).contains('..');
}

@AckModel(additionalProperties: AckAdditionalPropertiesMode.discard)
final class DeckWorkspace with _$DeckWorkspaceAck {
  final String projectDir;

  @AckField(schema: _safeWorkspacePathSchema)
  final String slidesPath;

  @AckField(schema: _safeWorkspacePathSchema)
  final String outputDir;

  DeckWorkspace({String? projectDir, String? slidesPath, String? outputDir})
    : projectDir = projectDir ?? '.',
      slidesPath = slidesPath ?? 'slides.md',
      outputDir = outputDir ?? '.superdeck' {
    _validatePath('slidesPath', this.slidesPath);
    _validatePath('outputDir', this.outputDir);
  }

  static void _validatePath(String name, String value) {
    if (!_isRelativeWithoutTraversal(value)) {
      throw ArgumentError.value(
        value,
        name,
        'must be a relative path without ".." traversal segments',
      );
    }
  }

  Directory get projectDirectory => Directory(p.normalize(projectDir));

  Directory get superdeckDir =>
      Directory(p.normalize(p.join(projectDir, outputDir)));

  File get deckJson => File(p.join(superdeckDir.path, 'superdeck.json'));
  File get deckFullJson =>
      File(p.join(superdeckDir.path, 'superdeck_full.json'));

  /// Path for reading deck JSON from bundled Flutter assets.
  ///
  /// This intentionally ignores [projectDir] because runtime asset keys are
  /// always relative to the app bundle root.
  String get bundledDeckJsonPath =>
      _normalizeBundledPath(p.join(outputDir, 'superdeck.json'));

  File get buildStatusJson =>
      File(p.join(superdeckDir.path, 'build_status.json'));

  File get slidesFile => File(p.join(projectDir, slidesPath));

  File get pubspecFile => File(p.join(projectDir, 'pubspec.yaml'));

  static final fromJson = DeckWorkspaceSchema.fromJson;

  static DeckWorkspace parse(Map<String, Object?> map) =>
      DeckWorkspaceSchema.parse(map);

  /// Returns `true` when [value] is a relative path that does not contain
  /// `..` as a path segment. Filenames that happen to contain `..` (e.g.
  /// `my..file.md`) are allowed because `p.split` only yields `..` for an
  /// actual traversal segment.
  static String _normalizeBundledPath(String path) {
    final normalized = p.posix.normalize(path.replaceAll('\\', '/'));
    return normalized.startsWith('./') ? normalized.substring(2) : normalized;
  }
}
