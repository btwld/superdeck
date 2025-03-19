import 'dart:async';

import 'package:logging/logging.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_builder/src/parsers/markdown_parser.dart';

import '../cache/slide_cache.dart';
import '../parsers/comment_parser.dart' show CommentParser;
import '../parsers/section_parser.dart';
import 'task.dart';
import 'task_context.dart';
import 'task_exception.dart';
import 'task_metrics.dart';

/// Manages the execution of a series of [Task] instances to process slides.
/// It handles loading markdown content, parsing slides, executing tasks,
/// cleaning up assets, and saving the processed slides.
class TaskPipeline {
  /// List of tasks to execute for each slide.
  final List<Task> tasks;
  final DeckConfiguration configuration;
  final FileSystemPresentationRepository store;
  final SlideCache? _cache;

  final bool _parallelTasks;
  final int _concurrentSlides;
  final Logger _logger = Logger('TaskPipeline');

  final StreamController<TaskMetrics> _metricsController =
      StreamController<TaskMetrics>.broadcast();

  /// Stream of metrics for each task execution
  Stream<TaskMetrics> get metrics => _metricsController.stream;

  TaskPipeline({
    required this.tasks,
    required this.configuration,
    required this.store,
    SlideCache? cache,
    bool parallelTasks = false,
    int concurrentSlides = 4,
  })  : _cache = cache,
        _parallelTasks = parallelTasks,
        _concurrentSlides = concurrentSlides;

  /// Processes an individual slide by executing all tasks sequentially or in parallel.
  Future<TaskContext> _processSlide(TaskContext context) async {
    if (_parallelTasks) {
      // Split tasks into those that can run in parallel and those that must run sequentially
      final parallelTasks = <Task>[];
      final sequentialTasks = <Task>[];

      for (var task in tasks) {
        if (task.canRunInParallel) {
          parallelTasks.add(task);
        } else {
          sequentialTasks.add(task);
        }
      }

      // Run parallel tasks first
      if (parallelTasks.isNotEmpty) {
        final futures =
            parallelTasks.map((task) => _runTask(task, context.clone()));
        await Future.wait(futures);
      }

      // Then run sequential tasks
      for (var task in sequentialTasks) {
        await _runTask(task, context);
      }
    } else {
      // Run all tasks sequentially
      for (var task in tasks) {
        await _runTask(task, context);
      }
    }

    return context;
  }

  /// Run a single task with metrics collection and error handling
  Future<void> _runTask(Task task, TaskContext context) async {
    final stopwatch = Stopwatch()..start();
    try {
      await task.run(context);
      stopwatch.stop();

      _metricsController.add(TaskMetrics(
        taskName: task.name,
        slideIndex: context.slideIndex,
        duration: stopwatch.elapsed,
      ));
    } on Exception catch (e, stackTrace) {
      stopwatch.stop();

      // Log the error with metrics
      _metricsController.add(TaskMetrics(
        taskName: task.name,
        slideIndex: context.slideIndex,
        duration: stopwatch.elapsed,
        success: false,
        errorMessage: e.toString(),
      ));

      // Wrap and rethrow the exception with additional context.
      Error.throwWithStackTrace(
        TaskException(task.name, e, context.slideIndex),
        stackTrace,
      );
    }
  }

  Future<Iterable<Slide>> run() async {
    await store.initialize();

    // Load raw markdown content
    final markdownRaw = await store.readDeckMarkdown();

    // Initialize the markdown parser
    final markdownParser = MarkdownParser();

    // Parse the raw markdown into individual raw slides
    final rawSlides = markdownParser.parse(markdownRaw);

    _logger.info(
        'Processing ${rawSlides.length} slides with $_concurrentSlides concurrent workers');

    final processedSlides = <Slide>[];

    // Process slides in batches to limit concurrency
    for (var i = 0; i < rawSlides.length; i += _concurrentSlides) {
      final end = (i + _concurrentSlides < rawSlides.length)
          ? i + _concurrentSlides
          : rawSlides.length;

      final batch = rawSlides.sublist(i, end);
      final futures = <Future<TaskContext>>[];

      for (var j = 0; j < batch.length; j++) {
        final index = i + j;
        final rawSlide = batch[j];

        // Check if we have a cached version of this slide
        if (_cache != null) {
          final cachedSlide = await _cache.getCachedSlide(rawSlide);
          if (cachedSlide != null) {
            _logger.info('Using cached slide for index $index');
            processedSlides.add(cachedSlide);
            continue;
          }
        }

        // No cache hit, process the slide
        futures.add(_processSlide(TaskContext(index, rawSlide, store)));
      }

      // Wait for this batch to complete
      final results = await Future.wait(futures);

      // Extract processed slides
      for (final result in results) {
        final slide = Slide(
          key: result.slide.key,
          options: SlideOptions.parse(result.slide.frontmatter),
          sections: SectionParser().parse(result.slide.content),
          comments: CommentParser().parse(result.slide.content),
        );

        // Cache the slide if caching is enabled
        if (_cache != null) {
          await _cache.cacheSlide(result.slide, slide);
        }

        processedSlides.add(slide);
      }
    }

    // Dispose of all tasks
    for (var task in tasks) {
      await task.dispose();
    }

    await _metricsController.close();

    // Save the processed slides
    await store.saveReferences(
      DeckReference(slides: processedSlides, config: configuration),
    );

    return processedSlides;
  }
}
