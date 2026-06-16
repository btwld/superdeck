import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';

/// Context passed to build plugins while transforming a content block.
///
/// The context identifies the slide, section, and block currently being
/// transformed, and provides helpers for writing generated files inside the
/// active SuperDeck build output directory.
final class DeckBuildContext {
  /// The workspace being built.
  final DeckWorkspace workspace;

  /// The stable key for the slide that contains the current block.
  final String slideKey;

  /// The zero-based index of the slide in the deck.
  final int slideIndex;

  /// The zero-based index of the section within the current slide.
  final int sectionIndex;

  /// The zero-based index of the block within the current section.
  final int blockIndex;

  /// Creates context for a single build-plugin transform call.
  const DeckBuildContext({
    required this.workspace,
    required this.slideKey,
    required this.slideIndex,
    required this.sectionIndex,
    required this.blockIndex,
  });

  static String _normalizeOutputRelativePath(String path) {
    final normalized = p.posix.normalize(path.replaceAll(r'\', '/'));
    if (normalized == '.' ||
        normalized == '..' ||
        normalized.startsWith('../') ||
        p.posix.isAbsolute(normalized)) {
      throw ArgumentError.value(
        path,
        'relativePath',
        'must be a relative path inside the build output directory',
      );
    }

    return normalized.startsWith('./') ? normalized.substring(2) : normalized;
  }

  /// Returns a file path inside the active build output directory.
  ///
  /// [relativePath] must be a relative path that stays inside the output
  /// directory. This method does not create the file or its parent directories.
  ///
  /// Throws [ArgumentError] when [relativePath] is absolute or escapes the build
  /// output directory.
  File outputFile(String relativePath) {
    final normalized = _normalizeOutputRelativePath(relativePath);

    return File(
      p.joinAll([workspace.superdeckDir.path, ...p.posix.split(normalized)]),
    );
  }

  /// Returns the Markdown asset path for a generated output file.
  ///
  /// Use this with the same [relativePath] passed to [outputFile] when writing a
  /// content transform that references generated assets.
  ///
  /// Throws [ArgumentError] when [relativePath] is absolute or escapes the build
  /// output directory.
  String assetPath(String relativePath) {
    final normalized = _normalizeOutputRelativePath(relativePath);

    return p.posix.join(workspace.outputDir.replaceAll(r'\', '/'), normalized);
  }
}

/// Base class for SuperDeck build-time content transform plugins.
///
/// Build plugins are registered with the SuperDeck build pipeline and run
/// against parsed [ContentBlock]s before build output is written. Subclasses
/// should be `final`, `base`, or `sealed`, provide a stable non-empty [id], and
/// override [transformContentBlock] when they rewrite slide content.
abstract base class DeckBuildPlugin extends DeckPlugin {
  /// Creates a build plugin.
  const DeckBuildPlugin();

  /// Stable identifier used for build plugin registration and diagnostics.
  ///
  /// IDs must be non-empty and unique within one build pipeline.
  @override
  String get id;

  /// Transforms a parsed content [block].
  ///
  /// The default implementation returns [block] unchanged. Override this method
  /// to rewrite block content, generate assets through [DeckBuildContext], or
  /// validate plugin-specific syntax. Throw [DeckFormatException] when the
  /// failure comes from invalid slide content and should point back to the
  /// authoring source.
  FutureOr<ContentBlock> transformContentBlock(
    ContentBlock block,
    DeckBuildContext context,
  ) {
    return block;
  }

  /// Releases resources owned by this plugin.
  ///
  /// Override this when the plugin owns browsers, file handles, isolates, or
  /// other long-lived resources. The build pipeline attempts to dispose every
  /// registered plugin even if one plugin fails during disposal.
  FutureOr<void> dispose() {}
}
