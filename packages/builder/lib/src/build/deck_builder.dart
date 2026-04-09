import 'dart:async';

import 'package:logging/logging.dart';
import 'package:superdeck_core/superdeck_core.dart';

import 'build_event.dart';
import '../parsers/comment_parser.dart';
import '../parsers/markdown_parser.dart';
import '../parsers/raw_slide_schema.dart';
import '../parsers/section_parser.dart';
import 'task_exception.dart';
import '../tasks/asset_generation_task.dart';
import '../tasks/dart_formatter_task.dart';
import '../tasks/slide_context.dart';
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
  final int _concurrentSlides;

  DeckBuilder({
    required this.tasks,
    required this.workspace,
    required this.store,
    int concurrentSlides = 4,
  }) : _concurrentSlides = concurrentSlides;

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

    store.clearGeneratedAssets();

    final markdownRaw = await store.readDeckMarkdown();
    final markdownParser = MarkdownParser();
    final rawSlides = markdownParser.parse(markdownRaw);

    final processedSlides = await _processAll(rawSlides);

    await store.saveReferences(processedSlides);
    await store.saveBuildStatus(
      phase: DeckBuildPhase.success,
      slideCount: processedSlides.length,
    );

    _logger.info('Build completed: ${processedSlides.length} slides processed');

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

  Future<List<Slide>> _processAll(List<RawSlideMarkdown> rawSlides) async {
    _logger.info(
      'Processing ${rawSlides.length} slides with $_concurrentSlides concurrent workers',
    );

    final processedSlides = <Slide>[];

    for (var i = 0; i < rawSlides.length; i += _concurrentSlides) {
      final end = (i + _concurrentSlides < rawSlides.length)
          ? i + _concurrentSlides
          : rawSlides.length;

      final batch = rawSlides.sublist(i, end);
      final futures = <Future<SlideContext>>[];

      for (var j = 0; j < batch.length; j++) {
        final index = i + j;
        futures.add(_processSlide(SlideContext(index, batch[j])));
      }

      final results = await Future.wait(futures);
      final slidesToAdd = results.map(_buildSlide);
      processedSlides.addAll(slidesToAdd);
    }

    return processedSlides;
  }

  Future<SlideContext> _processSlide(SlideContext context) async {
    for (final task in tasks) {
      await _runTask(task, context);
    }
    return context;
  }

  Future<void> _runTask(Task task, SlideContext context) async {
    try {
      await task.run(context);
    } on Exception catch (error, stackTrace) {
      _logger.severe(
        'Task "${task.name}" failed for slide ${context.slideIndex}: $error',
      );
      _logger.severe('Stack trace: $stackTrace');

      Error.throwWithStackTrace(
        TaskException(task.name, error, context.slideIndex),
        stackTrace,
      );
    }
  }

  Slide _buildSlide(SlideContext result) {
    return Slide(
      key: result.slide.key,
      options: SlideOptions.parse(result.slide.frontmatter),
      sections: SectionParser().parse(result.slide.content),
      comments: CommentParser().parse(result.slide.content),
    );
  }
}

/// Supported entry point for the default SuperDeck build pipeline.
final class StandardDeckBuildPipeline {
  const StandardDeckBuildPipeline._();

  static DeckBuilder create({
    required DeckWorkspace workspace,
    required DeckBuildStore store,
    Map<String, Object?>? browserLaunchOptions,
    int concurrentSlides = 4,
  }) {
    return DeckBuilder(
      tasks: [
        DartFormatterTask(),
        AssetGenerationTask.withDefaults(
          store: store,
          browserLaunchOptions: browserLaunchOptions,
        ),
      ],
      workspace: workspace,
      store: store,
      concurrentSlides: concurrentSlides,
    );
  }
}
