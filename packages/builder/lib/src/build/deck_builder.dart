import 'dart:async';

import 'package:superdeck_core/superdeck_core.dart';

import 'build_event.dart';
import '../parsers/markdown_parser.dart';
import 'slide_processor.dart';
import '../tasks/task.dart';

/// Builds decks from markdown content by processing slides through a series of tasks.
///
/// Handles loading markdown content, parsing slides, executing build tasks,
/// managing generated assets, and saving the compiled deck.
class DeckBuilder {
  /// List of tasks to execute for each slide.
  final List<Task> tasks;
  final DeckWorkspace workspace;
  final DeckBuildStore store;
  final Logger _logger = Logger('DeckBuilder');

  late final SlideProcessor _processor;

  DeckBuilder({
    required this.tasks,
    required this.workspace,
    required this.store,
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
    _logger.info('Starting build()...');
    await store.initialize();

    // Write building status at the start
    await store.saveBuildStatus(phase: DeckBuildPhase.building);

    // Clear generated assets from previous builds
    store.clearGeneratedAssets();

    // Load raw markdown content
    _logger.info('Loading markdown content...');
    final markdownRaw = await store.readDeckMarkdown();
    _logger.info(
      'Loaded ${markdownRaw.length} characters of markdown content',
    );

    // Initialize the markdown parser
    _logger.info('Initializing markdown parser...');
    final markdownParser = MarkdownParser();

    // Parse the raw markdown into individual raw slides
    _logger.info('Parsing markdown into slides...');
    final rawSlides = markdownParser.parse(markdownRaw);
    _logger.info('Parsed ${rawSlides.length} raw slides');

    // Process all slides through the processor
    final processedSlides = await _processor.processAll(
      rawSlides,
      tasks,
      store,
    );

    // Save the processed slides
    await store.saveReferences(processedSlides);
    await store.saveBuildStatus(
      phase: DeckBuildPhase.success,
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
