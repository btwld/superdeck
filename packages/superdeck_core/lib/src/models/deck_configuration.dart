import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:path/path.dart' as p;

import '../helpers/mappers.dart';
import '../schema/schema.dart';

part 'deck_configuration.mapper.dart';

@MappableClass(
  includeCustomMappers: [
    DirectoryMapper(),
    FileMapper(),
  ],
)
class DeckConfiguration with DeckConfigurationMappable {
  final superdeckDir = Directory('.superdeck');
  late final deckJson = File(p.join(superdeckDir.path, 'superdeck.json'));
  late final assetsDir = Directory(p.join(superdeckDir.path, 'assets'));
  late final assetsRefJson =
      File(p.join(superdeckDir.path, 'generated_assets.json'));
  late final slidesFile = File('slides.md');

  DeckConfiguration({
    File? slidesMarkdown,
  });

  File get pubspecFile => File('pubspec.yaml');

  static DeckConfiguration parse(Map<String, dynamic> map) {
    schema.validateOrThrow(map);
    return DeckConfigurationMapper.fromMap(map);
  }

  static final schema = Ok.object(
    {
      'slidesMarkdown': Ok.string(),
    },
  );

  static File get defaultFile => File('superdeck.yaml');
}
