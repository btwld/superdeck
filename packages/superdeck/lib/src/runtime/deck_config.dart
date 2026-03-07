import 'package:superdeck_core/superdeck_core.dart';

sealed class DeckConfig {
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
}

final class LocalDeckConfig extends DeckConfig {
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

final class BundledDeckConfig extends DeckConfig {
  final String deckAssetPath;

  const BundledDeckConfig({
    this.deckAssetPath = DeckArtifacts.bundledDeckAssetPath,
    super.projectDir,
    super.outputDir,
    super.assetsPath,
  });
}
