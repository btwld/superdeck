import 'dart:async';

import 'package:logging/logging.dart';
import 'package:superdeck_builder/src/parsers/markdown_parser.dart';
import 'package:superdeck_core/superdeck_core.dart';

import 'build_event.dart';
import 'slide_processor.dart';
import 'tasks/task.dart';

/// Builds decks from markdown content by processing slides through a series of tasks.
///
/// Handles loading markdown content, parsing slides, executing build tasks,
/// managing generated assets, and saving the compiled deck.
class DeckBuilder {
  /// List of tasks to execute for each slide.
  final List<Task> tasks;
  final DeckWorkspace configuration;
  final DeckService deckService;
  final Logger _logger = Logger('DeckBuilder');

  late final SlideProcessor _processor;

  DeckBuilder({
    required this.tasks,
    required this.configuration,
    required this.deckService,
    int concurrentSlides = 4,
  }) {
    _processor = SlideProcessor(concurrentSlides: concurrentSlides);
  }

  /// Builds the deck and watches for changes, emitting build events as a stream.
  ///
  /// Emits [BuildStarted] before each build, [BuildCompleted] with slides on success,
  /// or [BuildFailed] with error details on failure.
  ///
  /// The stream continues indefinitely, rebuilding on file changes.
  Stream<BuildEvent> watchAndBuild() async* {
    // Initial build
    yield const BuildStarted();
    try {
      final slides = await build();
      yield BuildCompleted(slides.toList());
    } catch (e, stackTrace) {
      await deckService.saveBuildStatus(
        status: 'failure',
        error: e,
        stackTrace: stackTrace,
      );
      yield BuildFailed(e, stackTrace);
    }

    // Watch for changes to the slides file
    final fileWatcher = FileWatcher(configuration.slidesFile);
    await for (final _ in fileWatcher.watch()) {
      yield const BuildStarted();
      try {
        final slides = await build();
        yield BuildCompleted(slides.toList());
      } catch (e, stackTrace) {
        await deckService.saveBuildStatus(
          status: 'failure',
          error: e,
          stackTrace: stackTrace,
        );
        yield BuildFailed(e, stackTrace);
      }
    }
  }

  Future<Iterable<Slide>> build() async {
    _logger.info('DeckBuilder: Starting build()...');
    await deckService.initialize();

    // Write building status at the start
    await deckService.saveBuildStatus(status: 'building');

    // Clear generated assets from previous builds
    deckService.clearGeneratedAssets();

    // Load raw markdown content
    _logger.info('DeckBuilder: Loading markdown content...');
    final markdownRaw = await deckService.readDeckMarkdown();
    _logger.info(
      'DeckBuilder: Loaded ${markdownRaw.length} characters of markdown content',
    );

    // Initialize the markdown parser
    _logger.info('DeckBuilder: Initializing markdown parser...');
    final markdownParser = MarkdownParser();

    // Parse the raw markdown into individual raw slides
    _logger.info('DeckBuilder: Parsing markdown into slides...');
    final rawSlides = markdownParser.parse(markdownRaw);
    _logger.info('DeckBuilder: Parsed ${rawSlides.length} raw slides');

    // Process all slides through the processor
    final processedSlides = await _processor.processAll(
      rawSlides,
      tasks,
    );

    // Save the processed slides
    await deckService.saveReferences(
      Deck(slides: processedSlides, configuration: configuration),
    );
    await deckService.saveBuildStatus(
      status: 'success',
      slideCount: processedSlides.length,
    );

    return processedSlides;
  }

  /// Disposes all tasks and releases resources.
  ///
  /// Call this when done with the builder, especially after watch mode ends.
  /// This ensures resources like browser instances are properly cleaned up.
  Future<void> dispose() async {
    // Convert FutureOr<void> to Future<void> for Future.wait compatibility
    await Future.wait(tasks.map((task) async => task.dispose()));
  }
}
