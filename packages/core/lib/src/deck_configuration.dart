import 'dart:io';

import 'package:ack/ack.dart';
import 'package:path/path.dart' as p;

final class DeckConfiguration {
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
  /// Rejects paths containing '..' or absolute paths for relative-only fields.
  static String _validateRelativePath(
    String? userPath,
    String defaultPath,
    String pathType,
  ) {
    final path = userPath ?? defaultPath;

    // Reject paths with traversal sequences
    if (path.contains('..')) {
      throw ArgumentError(
        '$pathType cannot contain path traversal sequences "..": $path',
      );
    }

    // Reject absolute paths for paths that should be relative
    if (p.isAbsolute(path)) {
      throw ArgumentError('$pathType must be a relative path: $path');
    }

    return path;
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
    final validated = _validateRelativePath(
      assetsPath,
      'assets',
      'assetsPath',
    );
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

  DeckConfiguration copyWith({
    String? projectDir,
    String? slidesPath,
    String? outputDir,
    String? assetsPath,
  }) {
    return DeckConfiguration(
      projectDir: projectDir ?? this.projectDir,
      slidesPath: slidesPath ?? this.slidesPath,
      outputDir: outputDir ?? this.outputDir,
      assetsPath: assetsPath ?? this.assetsPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (projectDir != null) 'projectDir': projectDir,
      if (slidesPath != null) 'slidesPath': slidesPath,
      if (outputDir != null) 'outputDir': outputDir,
      if (assetsPath != null) 'assetsPath': assetsPath,
    };
  }

  static DeckConfiguration fromMap(Map<String, dynamic> map) {
    return DeckConfiguration(
      projectDir: map['projectDir'] as String?,
      slidesPath: map['slidesPath'] as String?,
      outputDir: map['outputDir'] as String?,
      assetsPath: map['assetsPath'] as String?,
    );
  }

  static DeckConfiguration parse(Map<String, dynamic> map) {
    schema.parse(map);
    return fromMap(map);
  }

  static final schema = Ack.object({
    'projectDir': Ack.string().nullable().optional(),
    'slidesPath': Ack.string().nullable().optional(),
    'outputDir': Ack.string().nullable().optional(),
    'assetsPath': Ack.string().nullable().optional(),
  });

  static File get defaultFile => File('superdeck.yaml');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeckConfiguration &&
          runtimeType == other.runtimeType &&
          projectDir == other.projectDir &&
          slidesPath == other.slidesPath &&
          outputDir == other.outputDir &&
          assetsPath == other.assetsPath;

  @override
  int get hashCode =>
      Object.hash(projectDir, slidesPath, outputDir, assetsPath);
}
