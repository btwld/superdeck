import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';

import 'mermaid_generator.dart';

/// Build-time plugin that renders fenced Mermaid blocks to PNGs.
final class MermaidBuildPlugin extends DeckBuildPlugin {
  static final _mermaidFencePattern = RegExp(
    r'^[ \t]*```mermaid[ \t]*\r?\n([\s\S]*?)\r?\n^[ \t]*```[ \t]*$',
    multiLine: true,
  );

  final MermaidGenerator _generator;

  MermaidBuildPlugin({
    Map<String, Object?> configuration = const {},
    MermaidGenerator? generator,
  }) : _generator = _createGenerator(
         configuration: configuration,
         generator: generator,
       );

  static MermaidGenerator _createGenerator({
    required Map<String, Object?> configuration,
    required MermaidGenerator? generator,
  }) {
    if (generator != null && configuration.isNotEmpty) {
      throw ArgumentError.value(
        configuration,
        'configuration',
        'must be empty when a custom MermaidGenerator is provided',
      );
    }

    return generator ?? MermaidGenerator(configuration: configuration);
  }

  @override
  String get id => 'superdeck.mermaid';

  Future<String> _transformContentBlock(
    ContentBlock block,
    DeckBuildContext context,
  ) async {
    final matches = _mermaidFencePattern
        .allMatches(block.content)
        .toList(growable: false);
    if (matches.isEmpty) return block.content;

    final buffer = StringBuffer();
    var lastEnd = 0;

    for (final match in matches) {
      buffer.write(block.content.substring(lastEnd, match.start));

      final syntax = match.group(1)!;
      final assetPath = await _renderMermaidImage(
        syntax,
        block: block,
        context: context,
        offset: match.start,
      );
      buffer.write('![Mermaid diagram]($assetPath)');

      lastEnd = match.end;
    }

    buffer.write(block.content.substring(lastEnd));

    return buffer.toString();
  }

  @override
  Future<ContentBlock> transformContentBlock(
    ContentBlock block,
    DeckBuildContext context,
  ) async {
    final content = await _transformContentBlock(block, context);

    return content == block.content ? block : block.copyWith(content: content);
  }

  @override
  Future<void> dispose() async {
    await _generator.dispose();
  }

  Future<String> _renderMermaidImage(
    String syntax, {
    required ContentBlock block,
    required DeckBuildContext context,
    required int offset,
  }) async {
    final cacheKey = _cacheKey(syntax);
    final fileName = 'mermaid_$cacheKey.png';
    final outputFile = context.outputFile(p.posix.join('mermaid', fileName));
    final outputDir = outputFile.parent;

    await outputDir.create(recursive: true);
    if (!await _hasCachedImage(outputFile)) {
      try {
        final pngBytes = await _generator.render(syntax);
        await _writeImageAtomically(outputFile, pngBytes);
      } catch (error, stackTrace) {
        Error.throwWithStackTrace(
          DeckFormatException(
            'Failed to render Mermaid diagram '
            'at slide "${context.slideKey}", section ${context.sectionIndex}, '
            'block ${context.blockIndex}: $error',
            block.content,
            offset,
          ),
          stackTrace,
        );
      }
    }

    return context.assetPath(p.posix.join('mermaid', fileName));
  }

  Future<bool> _hasCachedImage(File file) async {
    return await file.exists() && await file.length() > 0;
  }

  Future<void> _writeImageAtomically(
    File outputFile,
    List<int> pngBytes,
  ) async {
    final tempFile = File('${outputFile.path}.tmp');
    try {
      await tempFile.writeAsBytes(pngBytes, flush: true);
      await tempFile.rename(outputFile.path);
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  String _cacheKey(String syntax) {
    final payload = jsonEncode({
      'source': syntax,
      'configuration': _canonicalize(_generator.configuration),
    });

    return generateValueHash(payload);
  }

  Object? _canonicalize(Object? value) {
    if (value is Map) {
      final entries =
          value.entries
              .map((entry) => (key: entry.key.toString(), value: entry.value))
              .toList()
            ..sort((a, b) => a.key.compareTo(b.key));

      return {
        for (final entry in entries) entry.key: _canonicalize(entry.value),
      };
    }
    if (value is Iterable) {
      return value.map(_canonicalize).toList(growable: false);
    }

    return value;
  }
}
