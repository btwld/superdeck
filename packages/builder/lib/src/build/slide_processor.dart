import 'dart:async';

import 'package:logging/logging.dart';

import '../parsers/raw_slide_schema.dart';
import 'package:superdeck_core/superdeck_core.dart';

import 'task_exception.dart';
import '../parsers/comment_parser.dart' show CommentParser;
import '../parsers/section_parser.dart';
import '../tasks/slide_context.dart';
import '../tasks/task.dart';

/// Processes raw slide markdown into final Slide objects through a task pipeline.
///
/// Handles concurrency control and coordinates task execution for each slide.
class SlideProcessor {
  final int _concurrentSlides;
  final Logger _logger = Logger('SlideProcessor');

  SlideProcessor({int concurrentSlides = 4})
    : _concurrentSlides = concurrentSlides;

  Future<List<Slide>> processAll(
    List<RawSlideMarkdown> rawSlides,
    List<Task> tasks,
    DeckBuildStore store,
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

        futures.add(_processSlide(SlideContext(index, rawSlide, store), tasks));
      }

      final results = await Future.wait(futures);

      final slidesToAdd = await Future.wait(
        results.map((result) => _buildSlide(result)),
      );

      processedSlides.addAll(slidesToAdd);
    }

    return processedSlides;
  }

  Future<SlideContext> _processSlide(
    SlideContext context,
    List<Task> tasks,
  ) async {
    for (var task in tasks) {
      await _runTask(task, context);
    }
    return context;
  }

  Future<void> _runTask(Task task, SlideContext context) async {
    try {
      await task.run(context);
    } on Exception catch (e, stackTrace) {
      _logger.severe(
        'Task "${task.name}" failed for slide ${context.slideIndex}: $e',
      );
      _logger.severe('Stack trace: $stackTrace');

      // Wrap and rethrow the exception with additional context.
      Error.throwWithStackTrace(
        TaskException(task.name, e, context.slideIndex),
        stackTrace,
      );
    }
  }

  Future<Slide> _buildSlide(SlideContext result) async {
    return Slide(
      key: result.slide.key,
      options: SlideOptions.parse(result.slide.frontmatter),
      sections: SectionParser().parse(result.slide.content),
      comments: CommentParser().parse(result.slide.content),
    );
  }
}
