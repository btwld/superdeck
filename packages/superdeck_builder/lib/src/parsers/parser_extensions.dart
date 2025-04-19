/// Extensions for parser classes.
///
/// This file contains extension methods for the parser classes to provide
/// additional functionality.

import 'base_parser.dart';
import 'block_parser.dart';
import 'markdown_parser.dart';
import 'section_parser.dart';

/// Extension methods for [BaseParser].
extension BaseParserExtensions<T> on BaseParser<T> {
  /// Parses the content and returns the result, with error handling.
  T parseWithErrorHandling(String content) {
    try {
      return parse(content);
    } catch (e) {
      // Handle specific parser errors or rethrow
      rethrow;
    }
  }
}

/// Extensions for [BlockParser]
extension BlockParserExtensions on BlockParser {
  // Add block-specific parsing helpers here
}

/// Extensions for [SectionParser]
extension SectionParserExtensions on SectionParser {
  // Add section-specific parsing helpers here
}

/// Extensions for [MarkdownParser]
extension MarkdownParserExtensions on MarkdownParser {
  // Add markdown-specific parsing helpers here
}
