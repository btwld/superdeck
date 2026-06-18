import 'dart:async';

import 'package:logging/logging.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../parsers/comment_parser.dart';
import '../parsers/markdown_parser.dart';
import '../parsers/section_parser.dart';
import 'build_event.dart';
import 'deck_build_plugin.dart';

/// Builds decks from markdown content.
///
/// Handles loading markdown content, parsing slides, and saving the compiled
/// deck.
class DeckBuilder {
  final DeckWorkspace workspace;
  final DeckBuildStore store;
  final List<DeckBuildPlugin> plugins;
  final Logger _logger = Logger('DeckBuilder');
  Future<void> _lastBuild = Future<void>.value();

  DeckBuilder({
    required this.workspace,
    required this.store,
    List<DeckBuildPlugin> plugins = const [],
  }) : plugins = List.unmodifiable(_validatePlugins(plugins));

  static List<DeckBuildPlugin> _validatePlugins(List<DeckBuildPlugin> plugins) {
    final seenIds = <String>{};
    for (final plugin in plugins) {
      final id = plugin.id.trim();
      if (id.isEmpty) {
        throw ArgumentError.value(
          plugin.id,
          'plugins',
          'Build plugin id must not be empty.',
        );
      }
      if (!seenIds.add(id)) {
        throw ArgumentError.value(
          plugin.id,
          'plugins',
          'Duplicate build plugin id "$id".',
        );
      }
    }

    return plugins;
  }

  /// Builds the deck and watches for changes, emitting build events as a stream.
  ///
  /// Emits [BuildStarted] before each build, [BuildCompleted] with slides on success,
  /// or [BuildFailed] with error details on failure.
  ///
  /// The stream continues indefinitely, rebuilding on file changes.
  Stream<BuildEvent> watchAndBuild() async* {
    final fileChanges = StreamIterator<void>(
      FileWatcher(workspace.slidesFile).watch(),
    );
    var nextChange = fileChanges.moveNext();
    try {
      yield const BuildStarted();
      yield* _buildAndEmit();

      while (await nextChange) {
        nextChange = fileChanges.moveNext();
        yield const BuildStarted();
        yield* _buildAndEmit();
      }
    } finally {
      await fileChanges.cancel();
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

  Future<Iterable<Slide>> build() {
    final buildFuture = _lastBuild.then((_) => _build());
    _lastBuild = buildFuture.then<void>((_) {}).catchError((_) {});

    return buildFuture;
  }

  Future<Iterable<Slide>> _build() async {
    _logger.info('Starting build...');
    await store.initialize();
    await store.saveBuildStatus(phase: DeckBuildPhase.building);

    final markdownRaw = await store.readDeckMarkdown();
    final rawSlides = MarkdownParser().parse(markdownRaw);

    final parsedSlides = [
      for (final raw in rawSlides)
        Slide(
          key: raw.key,
          options: SlideOptions.parse(raw.frontmatter),
          sections: SectionParser().parse(raw.content),
          comments: CommentParser().parse(raw.content),
        ),
    ];
    final slides = await _applyBuildPlugins(parsedSlides);

    await store.saveReferences(slides);
    await store.saveBuildStatus(
      phase: DeckBuildPhase.success,
      slideCount: slides.length,
    );

    _logger.info('Build completed: ${slides.length} slides processed');
    return slides;
  }

  Future<void> dispose() async {
    for (final plugin in plugins) {
      try {
        await plugin.dispose();
      } catch (error, stackTrace) {
        _logger.warning(
          'Failed to dispose build plugin "${plugin.id}".',
          error,
          stackTrace,
        );
      }
    }
  }

  Future<List<Slide>> _applyBuildPlugins(List<Slide> slides) async {
    if (plugins.isEmpty) return slides;

    final transformedSlides = <Slide>[];
    for (var slideIndex = 0; slideIndex < slides.length; slideIndex++) {
      final slide = slides[slideIndex];
      final transformedSections = <SectionBlock>[];

      for (
        var sectionIndex = 0;
        sectionIndex < slide.sections.length;
        sectionIndex++
      ) {
        final section = slide.sections[sectionIndex];
        final transformedBlocks = <Block>[];

        for (
          var blockIndex = 0;
          blockIndex < section.blocks.length;
          blockIndex++
        ) {
          final block = section.blocks[blockIndex];
          if (block is! ContentBlock) {
            transformedBlocks.add(block);
            continue;
          }

          transformedBlocks.add(
            await _applyContentBlockPlugins(
              block,
              DeckBuildContext(
                workspace: workspace,
                slideKey: slide.key,
                slideIndex: slideIndex,
                sectionIndex: sectionIndex,
                blockIndex: blockIndex,
              ),
            ),
          );
        }

        transformedSections.add(section.copyWith(blocks: transformedBlocks));
      }

      transformedSlides.add(slide.copyWith(sections: transformedSections));
    }

    return transformedSlides;
  }

  Future<ContentBlock> _applyContentBlockPlugins(
    ContentBlock block,
    DeckBuildContext context,
  ) async {
    var transformedBlock = block;
    for (final plugin in plugins) {
      try {
        transformedBlock = await plugin.transformContentBlock(
          transformedBlock,
          context,
        );
      } on DeckFormatException {
        rethrow;
      } catch (error, stackTrace) {
        Error.throwWithStackTrace(
          Exception(
            'Build plugin "${plugin.id}" failed at slide "${context.slideKey}", '
            'section ${context.sectionIndex}, block ${context.blockIndex}: '
            '$error',
          ),
          stackTrace,
        );
      }
    }

    return transformedBlock;
  }
}
