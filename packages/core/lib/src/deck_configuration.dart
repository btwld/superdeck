import 'dart:io';

import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:path/path.dart' as p;

part 'deck_configuration.g.dart';
part 'deck_configuration.mapper.dart';

@AckModel()
@MappableClass()
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

  /// Validates a path to prevent directory traversal attacks.
  ///
  /// Rejects paths containing '..' as a path segment, but allows filenames
  /// that happen to contain '..' (e.g., '..config.png', 'foo..bar.txt').
  static String _validateRelativePath(
    String? userPath,
    String defaultPath,
    String pathType,
  ) {
    final pathValue = userPath ?? defaultPath;

    // Reject paths with '..' as a path segment (directory traversal)
    // Split by both forward and back slashes to handle all platforms
    final segments = pathValue.split(RegExp(r'[/\\]'));
    if (segments.contains('..')) {
      throw ArgumentError(
        '$pathType cannot contain path traversal sequences "..": $pathValue',
      );
    }

    // Reject absolute paths for paths that should be relative
    if (p.isAbsolute(pathValue)) {
      throw ArgumentError('$pathType must be a relative path: $pathValue');
    }

    return pathValue;
  }

  String get _baseDir => projectDir ?? '.';

  Directory get superdeckDir {
    final validated = _validateRelativePath(
      outputDir,
      '.superdeck',
      'outputDir',
    );
    return Directory(p.normalize(p.join(_baseDir, validated)));
  }

  File get deckJson => File(p.join(superdeckDir.path, 'superdeck.json'));
  File get deckFullJson =>
      File(p.join(superdeckDir.path, 'superdeck_full.json'));

  Directory get assetsDir {
    final validated = _validateRelativePath(assetsPath, 'assets', 'assetsPath');
    return Directory(p.join(superdeckDir.path, validated));
  }

  File get assetsRefJson =>
      File(p.join(superdeckDir.path, 'generated_assets.json'));
  File get buildStatusJson =>
      File(p.join(superdeckDir.path, 'build_status.json'));

  File get slidesFile {
    final validated = _validateRelativePath(
      slidesPath,
      'slides.md',
      'slidesPath',
    );
    return File(p.join(_baseDir, validated));
  }

  File get pubspecFile => File(p.join(_baseDir, 'pubspec.yaml'));

  Map<String, Object?> toMap() {
    return {
      if (projectDir != null) 'projectDir': projectDir,
      if (slidesPath != null) 'slidesPath': slidesPath,
      if (outputDir != null) 'outputDir': outputDir,
      if (assetsPath != null) 'assetsPath': assetsPath,
    };
  }

  static DeckConfiguration fromMap(Map<String, Object?> map) {
    return DeckConfiguration(
      projectDir: map['projectDir'] as String?,
      slidesPath: map['slidesPath'] as String?,
      outputDir: map['outputDir'] as String?,
      assetsPath: map['assetsPath'] as String?,
    );
  }

  static DeckConfiguration parse(Map<String, Object?> map) {
    schema.parse(map);
    return fromMap(map);
  }

  static final schema = deckConfigurationSchema.extend({
    'projectDir': Ack.string().optional(),
    'slidesPath': Ack.string().optional(),
    'outputDir': Ack.string().optional(),
    'assetsPath': Ack.string().optional(),
  }).passthrough();

  static File get defaultFile => File('superdeck.yaml');
}
