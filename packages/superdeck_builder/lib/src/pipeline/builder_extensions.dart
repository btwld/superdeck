import 'package:superdeck_core/superdeck_core.dart';

import '../parsers/section_parser.dart';
import 'builder_context.dart';

/// Extensions for the BuilderContext class
extension BuilderContextExt on BuilderContext {
  /// Rebuilds sections using the current slide content
  List<SectionBlock> rebuildSections() {
    return SectionParser().parse(slide.content);
  }

  /// Gets the slide's computed title from the front matter or content
  String? getTitle() {
    // Try to get title from frontmatter
    if (slide.frontmatter.containsKey('title')) {
      return slide.frontmatter['title'] as String?;
    }

    // Fallback: try to find the first heading
    final content = slide.content;
    final headingRegex = RegExp(r'^#\s+(.+)$', multiLine: true);
    final match = headingRegex.firstMatch(content);
    if (match != null) {
      return match.group(1);
    }

    return null;
  }

  /// Gets a path for an asset
  String getAssetPath(Asset asset) {
    return dataStore.getAssetPath(asset);
  }

  /// Creates a new custom image asset
  Asset createCustomImageAsset(String id) {
    return Asset(
      id: id,
      extension: AssetExtension.png,
      type: AssetType.custom,
    );
  }

  /// Replaces a range in the slide content
  void replaceContentRange(int start, int end, String replacement) {
    slide.content = slide.content.replaceRange(start, end, replacement);
  }

  /// Checks if the slide has a specific block type
  bool hasBlockType(String blockType) {
    final blocks =
        rebuildSections().expand((section) => section.blocks).toList();

    return blocks.any((block) => block.type == blockType);
  }
}
