import 'dart:io';

import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:path/path.dart' as p;

import 'contracts/deck_artifacts.dart';

part 'deck_workspace.g.dart';

@AckModel()
final class DeckWorkspace {
  final String? projectDir;
  final String? slidesPath;
  final String? outputDir;
  final String? assetsPath;

  DeckWorkspace({
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
      DeckArtifacts.outputDir,
      'outputDir',
    );
    return Directory(p.normalize(p.join(_baseDir, validated)));
  }

  File get deckJson =>
      File(p.join(superdeckDir.path, DeckArtifacts.deckJsonFile));
  File get deckFullJson =>
      File(p.join(superdeckDir.path, DeckArtifacts.deckFullJsonFile));

  Directory get assetsDir {
    final validated = _validateRelativePath(
      assetsPath,
      DeckArtifacts.assetsDir,
      'assetsPath',
    );
    return Directory(p.join(superdeckDir.path, validated));
  }

  File get assetsRefJson =>
      File(p.join(superdeckDir.path, DeckArtifacts.generatedAssetsJsonFile));
  File get buildStatusJson =>
      File(p.join(superdeckDir.path, DeckArtifacts.buildStatusJsonFile));

  File get slidesFile {
    final validated = _validateRelativePath(
      slidesPath,
      'slides.md',
      'slidesPath',
    );
    return File(p.join(_baseDir, validated));
  }

  File get pubspecFile => File(p.join(_baseDir, 'pubspec.yaml'));

  DeckWorkspace copyWith({
    String? projectDir,
    String? slidesPath,
    String? outputDir,
    String? assetsPath,
  }) {
    return DeckWorkspace(
      projectDir: projectDir ?? this.projectDir,
      slidesPath: slidesPath ?? this.slidesPath,
      outputDir: outputDir ?? this.outputDir,
      assetsPath: assetsPath ?? this.assetsPath,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (projectDir != null) 'projectDir': projectDir,
      if (slidesPath != null) 'slidesPath': slidesPath,
      if (outputDir != null) 'outputDir': outputDir,
      if (assetsPath != null) 'assetsPath': assetsPath,
    };
  }

  static DeckWorkspace fromMap(Map<String, Object?> map) {
    return DeckWorkspace(
      projectDir: map['projectDir'] as String?,
      slidesPath: map['slidesPath'] as String?,
      outputDir: map['outputDir'] as String?,
      assetsPath: map['assetsPath'] as String?,
    );
  }

  static DeckWorkspace parse(Map<String, Object?> map) {
    schema.parse(map);
    return fromMap(map);
  }

  static final schema = deckWorkspaceSchema.extend({
    'projectDir': Ack.string().optional(),
    'slidesPath': Ack.string().optional(),
    'outputDir': Ack.string().optional(),
    'assetsPath': Ack.string().optional(),
  }).passthrough();

  static File get defaultFile => File('superdeck.yaml');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeckWorkspace &&
          runtimeType == other.runtimeType &&
          projectDir == other.projectDir &&
          slidesPath == other.slidesPath &&
          outputDir == other.outputDir &&
          assetsPath == other.assetsPath;

  @override
  int get hashCode =>
      Object.hash(projectDir, slidesPath, outputDir, assetsPath);
}
