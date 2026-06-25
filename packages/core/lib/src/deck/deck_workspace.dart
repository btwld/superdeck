import 'dart:io';

import 'package:ack/ack.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:path/path.dart' as p;

part 'deck_workspace.mapper.dart';

@MappableClass()
final class DeckWorkspace with DeckWorkspaceMappable {
  final String projectDir;
  final String slidesPath;
  final String outputDir;

  DeckWorkspace({
    String? projectDir,
    String? slidesPath,
    String? outputDir,
  }) : projectDir = projectDir ?? '.',
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

  static final fromMap = DeckWorkspaceMapper.fromMap;

  static DeckWorkspace parse(Map<String, Object?> map) =>
      fromMap(Map<String, dynamic>.from(schema.parse(map)!));

  static final _safePath = Ack.string().refine(
    _isRelativeWithoutTraversal,
    message:
        'must be a relative path without ".." traversal segments'
        ' (absolute paths and parent-directory traversal are not allowed)',
  );

  static final schema = Ack.object({
    'projectDir': Ack.string().optional(),
    'slidesPath': _safePath.optional(),
    'outputDir': _safePath.optional(),
  }).passthrough();

  /// Returns `true` when [value] is a relative path that does not contain
  /// `..` as a path segment. Filenames that happen to contain `..` (e.g.
  /// `my..file.md`) are allowed because `p.split` only yields `..` for an
  /// actual traversal segment.
  static bool _isRelativeWithoutTraversal(String value) {
    if (p.isAbsolute(value)) return false;
    return !p.split(value).contains('..');
  }

  static String _normalizeBundledPath(String path) {
    final normalized = p.posix.normalize(path.replaceAll('\\', '/'));
    return normalized.startsWith('./') ? normalized.substring(2) : normalized;
  }
}
