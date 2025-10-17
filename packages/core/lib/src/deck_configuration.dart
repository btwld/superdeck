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

  String get _baseDir => projectDir ?? '.';

  Directory get superdeckDir =>
      Directory(p.normalize(p.join(_baseDir, outputDir ?? '.superdeck')));
  File get deckJson => File(p.join(superdeckDir.path, 'superdeck.json'));
  Directory get assetsDir =>
      Directory(p.join(superdeckDir.path, assetsPath ?? 'assets'));
  File get assetsRefJson =>
      File(p.join(superdeckDir.path, 'generated_assets.json'));
  File get buildStatusJson =>
      File(p.join(superdeckDir.path, 'build_status.json'));
  File get slidesFile => File(p.join(_baseDir, slidesPath ?? 'slides.md'));
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

  static final schema = Ack.object(
    {
      'projectDir': Ack.string().nullable().optional(),
      'slidesPath': Ack.string().nullable().optional(),
      'outputDir': Ack.string().nullable().optional(),
      'assetsPath': Ack.string().nullable().optional(),
    },
  );

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
