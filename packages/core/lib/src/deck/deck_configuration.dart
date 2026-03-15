import 'dart:io';

import 'package:ack/ack.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:path/path.dart' as p;

part 'deck_configuration.mapper.dart';

@MappableClass(ignoreNull: true)
final class DeckConfiguration with DeckConfigurationMappable {
  final String? projectDir;
  final String? slidesPath;
  final String? outputDir;
  final String? assetsPath;

  DeckConfiguration({
    this.projectDir,
    this.slidesPath,
    this.outputDir,
    this.assetsPath,
  });

  String get _baseDir => projectDir ?? '.';
  String get _outputDir => outputDir ?? '.superdeck';
  String get _assets => assetsPath ?? 'assets';
  String get _slides => slidesPath ?? 'slides.md';

  Directory get projectDirectory => Directory(p.normalize(_baseDir));

  Directory get superdeckDir =>
      Directory(p.normalize(p.join(_baseDir, _outputDir)));

  File get deckJson => File(p.join(superdeckDir.path, 'superdeck.json'));
  File get deckFullJson =>
      File(p.join(superdeckDir.path, 'superdeck_full.json'));

  /// Path for reading deck JSON from bundled Flutter assets.
  ///
  /// This intentionally ignores [projectDir] because runtime asset keys are
  /// always relative to the app bundle root.
  String get bundledDeckJsonPath =>
      _normalizeBundledPath(p.join(_outputDir, 'superdeck.json'));

  Directory get assetsDir => Directory(p.join(superdeckDir.path, _assets));

  /// Path for reading generated assets from bundled Flutter assets.
  ///
  /// This intentionally ignores [projectDir] because runtime asset keys are
  /// always relative to the app bundle root.
  String get bundledAssetsPath =>
      _normalizeBundledPath(p.join(_outputDir, _assets));

  File get assetsRefJson =>
      File(p.join(superdeckDir.path, 'generated_assets.json'));
  File get buildStatusJson =>
      File(p.join(superdeckDir.path, 'build_status.json'));

  File get slidesFile => File(p.join(_baseDir, _slides));

  File get pubspecFile => File(p.join(_baseDir, 'pubspec.yaml'));

  static final fromMap = DeckConfigurationMapper.fromMap;

  static DeckConfiguration parse(Map<String, Object?> map) =>
      fromMap(Map<String, dynamic>.from(schema.parse(map)!));

  static final _safePath = Ack.string().strictParsing().refine(
    _isRelativeWithoutTraversal,
    message:
        'must be a relative path without ".." traversal segments'
        ' (absolute paths and parent-directory traversal are not allowed)',
  );

  static final schema = Ack.object({
    'projectDir': Ack.string().strictParsing().optional(),
    'slidesPath': _safePath.optional(),
    'outputDir': _safePath.optional(),
    'assetsPath': _safePath.optional(),
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
