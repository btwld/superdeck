import 'dart:async';

import 'package:logging/logging.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../parsers/comment_parser.dart';
import '../parsers/markdown_parser.dart';
import '../parsers/section_parser.dart';
import 'build_event.dart';

/// Builds decks from markdown content.
///
/// Handles loading markdown content, parsing slides, and saving the compiled
/// deck.
class DeckBuilder {
  final DeckWorkspace workspace;
  final DeckBuildStore store;
  final Logger _logger = Logger('DeckBuilder');

  DeckBuilder({required this.workspace, required this.store});

  /// Builds the deck and watches for changes, emitting build events as a stream.
  ///
  /// Emits [BuildStarted] before each build, [BuildCompleted] with slides on success,
  /// or [BuildFailed] with error details on failure.
  ///
  /// The stream continues indefinitely, rebuilding on file changes.
  Stream<BuildEvent> watchAndBuild() async* {
    yield const BuildStarted();
    yield* _buildAndEmit();

    final fileWatcher = FileWatcher(workspace.slidesFile);
    await for (final _ in fileWatcher.watch()) {
      yield const BuildStarted();
      yield* _buildAndEmit();
    }
  }

  Stream<BuildEvent> _buildAndEmit() async* {
    try {
      final slides = await build();
      yield BuildCompleted(slides.toList());
    } catch (e, stackTrace) {
      await store.saveBuildStatus(
        phase: DeckBuildPhase.failure,
        error: e,
        stackTrace: stackTrace,
      );
      yield BuildFailed(e, stackTrace);
    }
  }

  Future<Iterable<Slide>> build() async {
    _logger.info('Starting build...');
    await store.initialize();
    await store.saveBuildStatus(phase: DeckBuildPhase.building);

    final markdownRaw = await store.readDeckMarkdown();
    final rawSlides = MarkdownParser().parse(markdownRaw);

    final slides = [
      for (final raw in rawSlides)
        Slide(
          key: raw.key,
          options: SlideOptions.parse(raw.frontmatter),
          sections: SectionParser().parse(raw.content),
          comments: CommentParser().parse(raw.content),
        ),
    ];

    await store.saveReferences(slides);
    await store.saveBuildStatus(
      phase: DeckBuildPhase.success,
      slideCount: slides.length,
    );

    _logger.info('Build completed: ${slides.length} slides processed');
    return slides;
  }
}
