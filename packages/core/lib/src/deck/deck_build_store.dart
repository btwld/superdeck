import 'package:markdown/markdown.dart' as md;

import '../markdown/markdown_json.dart';
import '../utils/extensions.dart';
import 'package:logging/logging.dart';
import '../utils/pretty_json.dart';
import 'deck_build_status.dart';
import 'deck_workspace.dart';
import 'slide_model.dart';

/// Build-side store used by CLI and builder commands.
///
/// Runtime loaders live in the `superdeck` package; this type stays in core
/// as the build-side storage primitive over the same workspace layout, while
/// domain data contracts live in model files.
class DeckBuildStore {
  DeckBuildStore({required this.workspace});

  final DeckWorkspace workspace;
  final Logger _logger = Logger('DeckBuildStore');

  Future<void> initialize() async {
    await workspace.deckJson.ensureExists(content: '[]');
    await workspace.buildStatusJson.ensureExists(
      content: prettyJson(
        DeckBuildStatus(
          phase: DeckBuildPhase.unknown,
          timestamp: DateTime.now(),
        ).toJson(),
      ),
    );
    await workspace.slidesFile.ensureExists(content: '');
  }

  Future<String> readDeckMarkdown() async {
    return workspace.slidesFile.readAsString();
  }

  Future<void> saveReferences(List<Slide> slides) async {
    final deckJson = prettyJson(
      slides.map((slide) => slide.toJson()).toList(growable: false),
    );
    await workspace.deckJson.writeAsString(deckJson);

    await _saveFullDeckReference(slides);
  }

  Future<void> saveBuildStatus({
    required DeckBuildPhase phase,
    int? slideCount,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    if (phase == DeckBuildPhase.failure && error != null) {
      _logger.severe('Build failed: $error', error, stackTrace);
    }

    final status = DeckBuildStatus(
      phase: phase,
      timestamp: DateTime.now(),
      slideCount: slideCount,
      error: phase == DeckBuildPhase.failure && error != null
          ? DeckBuildError(message: error.toString())
          : null,
    );

    await workspace.buildStatusJson.ensureWrite(prettyJson(status.toJson()));
  }

  Future<void> _saveFullDeckReference(List<Slide> slides) async {
    final converter = MarkdownAstConverter(
      extensionSet: md.ExtensionSet.gitHubWeb,
    );

    final slidesWithMarkdownJson = slides.map((slide) {
      final slideMap = slide.toJson();

      final sections = slideMap['sections'] as List<dynamic>;
      final processedSections = sections.map((section) {
        final sectionMap = Map<String, Object?>.from(section as Map);
        final blocks = sectionMap['blocks'] as List<dynamic>? ?? const [];

        final processedBlocks = blocks.map((block) {
          final blockMap = Map<String, Object?>.from(block as Map);

          if (blockMap.containsKey('content') &&
              blockMap['content'] is String) {
            final contentString = blockMap['content'] as String;
            final markdownAst = converter.toMap(
              contentString,
              includeMetadata: true,
            );
            blockMap['content'] = markdownAst;
          }

          return blockMap;
        }).toList();

        sectionMap['blocks'] = processedBlocks;
        return sectionMap;
      }).toList();

      slideMap['sections'] = processedSections;
      return slideMap;
    }).toList();

    final fullDeckJson = prettyJson(slidesWithMarkdownJson);
    await workspace.deckFullJson.writeAsString(fullDeckJson);
  }
}
