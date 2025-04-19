import 'dart:async';

import 'package:superdeck_core/superdeck_core.dart';

import '../parsers/comment_parser.dart';
import '../parsers/markdown_parser.dart';
import '../parsers/section_parser.dart';
import '../tasks/task.dart';
import 'builder_context.dart';
import 'builder_exception.dart';

/// Manages the execution of a series of [Task] instances to process slides.
/// It handles loading markdown content, parsing slides, executing tasks,
/// cleaning up assets, and saving the processed slides.
class BuilderPipeline {
  /// List of tasks to execute for each slide.
  final List<Task> tasks;
  final PresentationConfig configuration;
  final FileSystemPresentationRepository store;

  const BuilderPipeline({
    required this.tasks,
    required this.configuration,
    required this.store,
  });

  /// Processes an individual slide by executing all tasks sequentially.
  Future<BuilderContext> _processSlide(BuilderContext context) async {
    for (var task in tasks) {
      try {
        await task.run(context);
      } on Exception catch (e, stackTrace) {
        // Wrap and rethrow the exception with additional context.
        Error.throwWithStackTrace(
          BuilderTaskException(task.name, e, context.slideIndex),
          stackTrace,
        );
      }
    }

    return context;
  }

  Future<Iterable<Slide>> run() async {
    await store.initialize();

    // Load raw markdown content from the repository.
    final markdownRaw = await store.readDeckMarkdown();

    // Initialize the markdown parser with necessary extractors.
    final markdownParser = MarkdownParser();

    // Parse the raw markdown into individual raw slides.
    final rawSlides = markdownParser.parse(markdownRaw);

    // Prepare a list of futures to process each slide concurrently.
    final futures = <Future<BuilderContext>>[];

    for (var i = 0; i < rawSlides.length; i++) {
      futures.add(_processSlide(BuilderContext(i, rawSlides[i], store)));
    }

    // Await all slide processing tasks to complete.
    final results = await Future.wait(futures);

    // Extract the processed slides from the results.
    final finalizedSlides = results.map((result) => result.slide);

    final slides = finalizedSlides.map((slide) => Slide(
          key: slide.key,
          options: slide.frontmatter.isNotEmpty
              ? SlideOptions.parse(slide.frontmatter)
              : null,
          sections: SectionParser().parse(slide.content),
          comments: CommentParser().parse(slide.content),
        ));

    // Dispose of all tasks after processing.
    for (var task in tasks) {
      await task.dispose();
    }

    // Save the processed slides back to the repository.
    await store.saveReferences(
      Presentation(slides: slides.toList(), configuration: configuration),
    );

    return slides;
  }
}
