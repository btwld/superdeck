import 'package:superdeck_core/superdeck_core.dart';

sealed class DeckSource {
  const DeckSource();

  const factory DeckSource.local({String slidesPath, bool watch}) =
      LocalDeckSource;

  const factory DeckSource.bundle({String deckAssetPath}) = BundledDeckSource;
}

final class LocalDeckSource extends DeckSource {
  final String slidesPath;
  final bool watch;

  const LocalDeckSource({this.slidesPath = 'slides.md', this.watch = false});
}

final class BundledDeckSource extends DeckSource {
  final String deckAssetPath;

  const BundledDeckSource({
    this.deckAssetPath = DeckArtifacts.bundledDeckAssetPath,
  });
}
