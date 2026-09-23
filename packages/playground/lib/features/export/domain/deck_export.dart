import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../../core/domain/generated_image_asset.dart';

/// A generated deck laid out as a SuperDeck project: `slides.md` and its
/// artwork under `assets/`.
///
/// Generated slides name their images by bare asset key, which only this
/// app's in-memory store resolves. The export rewrites each one to
/// `assets/<key>`, a relative path any SuperDeck project loads.
final class DeckExport {
  static const _markdownPath = 'slides.md';
  static const _assetsFolder = 'assets';
  static const _fallbackName = 'SuperDeck deck';

  /// Suggested file name for the export, without an extension.
  final String name;

  /// File contents by path relative to the project root.
  final Map<String, List<int>> files;

  const DeckExport._({required this.name, required this.files});

  /// Builds the export for [slides] and the [images] generated for them.
  ///
  /// The export is named after [title], or the first slide's title without
  /// one. Images without bytes are left out; their slides no longer
  /// reference them.
  factory DeckExport.fromDeck({
    required List<Slide> slides,
    required List<GeneratedImageAsset> images,
    String? title,
  }) {
    var markdown = const SlideSerializer().serialize(slides);
    final assets = <String, List<int>>{};
    for (final image in images) {
      final bytes = image.bytes;
      if (bytes == null || bytes.isEmpty) continue;
      final key = AssetCacheStore.validateAssetKey(image.assetKey);
      final path = '$_assetsFolder/$key';
      markdown = markdown.replaceAll(
        RegExp('(?<![\\w./-])${RegExp.escape(key)}(?![\\w.-])'),
        path,
      );
      assets[path] = bytes;
    }

    return DeckExport._(
      name:
          _fileStem(title) ??
          _fileStem(_firstSlideTitle(slides)) ??
          _fallbackName,
      files: {_markdownPath: utf8.encode(markdown), ...assets},
    );
  }

  static String? _firstSlideTitle(List<Slide> slides) =>
      slides.isEmpty ? null : slides.first.options?.title;

  /// [title] made safe to use as a file name, or `null` when nothing usable
  /// is left.
  static String? _fileStem(String? title) {
    final stem = (title ?? '')
        .replaceAll(RegExp(r'[\x00-\x1f/\\:]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll(RegExp(r'^\.+'), '')
        .trim();

    return stem.isEmpty ? null : stem;
  }

  /// Encodes [files] as a zip archive.
  Uint8List toZip() {
    final archive = Archive();
    for (final MapEntry(key: path, value: bytes) in files.entries) {
      archive.addFile(ArchiveFile.bytes(path, bytes));
    }

    return ZipEncoder().encodeBytes(archive);
  }
}
