import 'package:dart_mappable/dart_mappable.dart';
import 'package:superdeck_core/superdeck_core.dart';

part 'deck_config.mapper.dart';

@MappableClass(
  discriminatorKey: 'type',
  includeSubClasses: [LocalDeckConfig, BundledDeckConfig],
)
sealed class DeckConfig with DeckConfigMappable {
  final String? projectDir;
  final String? outputDir;
  final String? assetsPath;

  const DeckConfig({this.projectDir, this.outputDir, this.assetsPath});

  const factory DeckConfig.local({
    String slidesPath,
    bool watch,
    String? projectDir,
    String? outputDir,
    String? assetsPath,
  }) = LocalDeckConfig;

  const factory DeckConfig.bundle({
    String deckAssetPath,
    String? projectDir,
    String? outputDir,
    String? assetsPath,
  }) = BundledDeckConfig;

  static final fromMap = DeckConfigMapper.fromMap;
}

@MappableClass(discriminatorValue: 'local')
final class LocalDeckConfig extends DeckConfig with LocalDeckConfigMappable {
  final String slidesPath;
  final bool watch;

  const LocalDeckConfig({
    this.slidesPath = 'slides.md',
    this.watch = false,
    super.projectDir,
    super.outputDir,
    super.assetsPath,
  });
}

@MappableClass(discriminatorValue: 'bundle')
final class BundledDeckConfig extends DeckConfig
    with BundledDeckConfigMappable {
  final String deckAssetPath;

  const BundledDeckConfig({
    this.deckAssetPath = DeckArtifacts.bundledDeckAssetPath,
    super.projectDir,
    super.outputDir,
    super.assetsPath,
  });
}
