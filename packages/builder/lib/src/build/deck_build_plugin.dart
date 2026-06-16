import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';

final class DeckBuildContext {
  final DeckWorkspace workspace;
  final String slideKey;
  final int slideIndex;
  final int sectionIndex;
  final int blockIndex;

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

  File outputFile(String relativePath) {
    final normalized = _normalizeOutputRelativePath(relativePath);

    return File(
      p.joinAll([workspace.superdeckDir.path, ...p.posix.split(normalized)]),
    );
  }

  String assetPath(String relativePath) {
    final normalized = _normalizeOutputRelativePath(relativePath);

    return p.posix.join(workspace.outputDir.replaceAll(r'\', '/'), normalized);
  }
}

abstract base class DeckBuildPlugin {
  const DeckBuildPlugin();

  String get id;

  FutureOr<ContentBlock> transformContentBlock(
    ContentBlock block,
    DeckBuildContext context,
  ) {
    return block;
  }

  FutureOr<void> dispose() {}
}
