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

  String get _baseDir => projectDir ?? '.';
  String get _outputDir => outputDir ?? '.superdeck';
  String get _assets => assetsPath ?? 'assets';
  String get _slides => slidesPath ?? 'slides.md';

  late final superdeckDir = Directory(
    p.normalize(p.join(_baseDir, _outputDir)),
  );

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

  Map<String, Object?> toMap() {
    return {
      if (projectDir != null) 'projectDir': projectDir,
      if (slidesPath != null) 'slidesPath': slidesPath,
      if (outputDir != null) 'outputDir': outputDir,
      if (assetsPath != null) 'assetsPath': assetsPath,
    };
  }

  static DeckConfiguration fromMap(Map<String, dynamic> map) {
    return DeckConfigurationMapper.fromMap(map);
  }

  static DeckConfiguration parse(Map<String, Object?> map) {
    schema.parse(map);
    return fromMap(map.cast<String, dynamic>());
  }

  static final schema = deckConfigurationSchema.extend({
    'projectDir': Ack.string().optional(),
    'slidesPath': Ack.string().optional(),
    'outputDir': Ack.string().optional(),
    'assetsPath': Ack.string().optional(),
  }).passthrough();

  static File get defaultFile => File('superdeck.yaml');

  static String _normalizeBundledPath(String path) {
    final normalized = p.posix.normalize(path.replaceAll('\\', '/'));
    return normalized.startsWith('./') ? normalized.substring(2) : normalized;
  }
}
