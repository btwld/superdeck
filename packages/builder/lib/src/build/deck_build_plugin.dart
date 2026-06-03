import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:superdeck_core/superdeck_core.dart';

typedef ContentBlockTransformer =
    FutureOr<ContentBlock> Function(
      ContentBlock block,
      DeckBuildContext context,
    );

typedef DeckBuildPluginDisposer = FutureOr<void> Function();

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

final class DeckBuildPlugin {
  final String id;
  final ContentBlockTransformer _transformContentBlock;
  final DeckBuildPluginDisposer? _dispose;

  DeckBuildPlugin({
    required this.id,
    required ContentBlockTransformer transformContentBlock,
    DeckBuildPluginDisposer? dispose,
  }) : _transformContentBlock = transformContentBlock,
       _dispose = dispose {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Build plugin id must not be empty.');
    }
  }

  Future<ContentBlock> transformContentBlock(
    ContentBlock block,
    DeckBuildContext context,
  ) async {
    return _transformContentBlock(block, context);
  }

  Future<void> dispose() async {
    final disposer = _dispose;
    if (disposer == null) return;

    await disposer();
  }
}
