import 'dart:async';

import 'package:superdeck_builder/src/parsers/raw_slide_schema.dart';
import 'package:superdeck_core/superdeck_core.dart';

import 'task_exception.dart';
import 'parsers/comment_parser.dart' show CommentParser;
import 'parsers/section_parser.dart';
import 'tasks/slide_context.dart';
import 'tasks/task.dart';

/// Processes raw slide markdown into final Slide objects through a task pipeline.
///
/// Handles concurrency control and coordinates task execution for each slide.
class SlideProcessor {
  final int _concurrentSlides;
  final Logger _logger = Logger('SlideProcessor');

  SlideProcessor({int concurrentSlides = 4})
    : _concurrentSlides = concurrentSlides;

  /// Processes all raw slides through the task pipeline with concurrency control.
  Future<List<Slide>> processAll(
    List<RawSlideMarkdown> rawSlides,
    List<Task> tasks,
    DeckService store,
  ) async {
    _logger.info(
      'Processing ${rawSlides.length} slides with $_concurrentSlides concurrent workers',
    );

    final processedSlides = <Slide>[];

    // Process slides in batches to limit concurrency
    for (var i = 0; i < rawSlides.length; i += _concurrentSlides) {
      final end = (i + _concurrentSlides < rawSlides.length)
          ? i + _concurrentSlides
          : rawSlides.length;

      final batch = rawSlides.sublist(i, end);
      final futures = <Future<SlideContext>>[];

      for (var j = 0; j < batch.length; j++) {
        final index = i + j;
        final rawSlide = batch[j];

        _logger.info(
          'DeckBuilder: Processing slide $index (key: ${rawSlide.key})',
        );

        futures.add(_processSlide(SlideContext(index, rawSlide, store), tasks));
      }

      // Wait for this batch to complete
      final results = await Future.wait(futures);

      // Extract processed slides using functional approach
      final slidesToAdd = await Future.wait(
        results.map((result) => _buildSlide(result)),
      );

      processedSlides.addAll(slidesToAdd);
    }

    return processedSlides;
  }

  /// Processes an individual slide by executing all tasks sequentially.
  Future<SlideContext> _processSlide(
    SlideContext context,
    List<Task> tasks,
  ) async {
    for (var task in tasks) {
      await _runTask(task, context);
    }
    return context;
  }

  /// Run a single task with timing and error handling
  Future<void> _runTask(Task task, SlideContext context) async {
    final stopwatch = Stopwatch()..start();
    _logger.info(
      'DeckBuilder: Running task "${task.name}" on slide ${context.slideIndex}',
    );
    try {
      await task.run(context);
      stopwatch.stop();
      _logger.info(
        'DeckBuilder: Task "${task.name}" completed for slide ${context.slideIndex} in ${stopwatch.elapsed}',
      );
    } on Exception catch (e, stackTrace) {
      stopwatch.stop();
      _logger.severe(
        'DeckBuilder: Task "${task.name}" failed for slide ${context.slideIndex}: $e',
      );
      _logger.severe('DeckBuilder: Stack trace: $stackTrace');

      // Wrap and rethrow the exception with additional context.
      Error.throwWithStackTrace(
        TaskException(task.name, e, context.slideIndex),
        stackTrace,
      );
    }
  }

  /// Builds final Slide from processed context
  Future<Slide> _buildSlide(SlideContext result) async {
    return Slide(
      key: result.slide.key,
      options: SlideOptions.parse(result.slide.frontmatter),
      sections: SectionParser().parse(result.slide.content),
      comments: CommentParser().parse(result.slide.content),
    );
  }
}
