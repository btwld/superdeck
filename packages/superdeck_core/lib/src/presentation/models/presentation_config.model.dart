import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:path/path.dart' as p;

import '../../../superdeck_core.dart';

part 'presentation_config.model.mapper.dart';

@MappableClass(
  includeCustomMappers: [
    DirectoryMapper(),
    FileMapper(),
  ],
)
class PresentationConfig with PresentationConfigMappable {
  final superdeckDir = Directory('.superdeck');
  late final deckJson = File(p.join(superdeckDir.path, 'superdeck.json'));
  late final assetsDir = Directory(p.join(superdeckDir.path, 'assets'));
  late final assetsRefJson =
      File(p.join(superdeckDir.path, 'generated_assets.json'));
  late final slidesFile = File('slides.md');

  PresentationConfig({
    File? slidesMarkdown,
  });

  File get pubspecFile => File('pubspec.yaml');

  static PresentationConfig parse(Map<String, dynamic> map) {
    schema.validateOrThrow(map, debugName: 'PresentationConfig');
    return PresentationConfigMapper.fromMap(map);
  }

  static final schema = Ack.object(
    {
      'slidesMarkdown': Ack.string.nullable(),
    },
  );

  static File get defaultFile => File('superdeck.yaml');
}
