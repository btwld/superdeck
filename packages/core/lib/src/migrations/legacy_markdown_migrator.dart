import '../tag_tokenizer.dart';
import '../models/block_model.dart';

final class LegacyMarkdownMigrator {
  const LegacyMarkdownMigrator._();

  static String migrateToV2(String source) {
    if (!source.contains('@${ContentBlock.legacyKey}')) {
      return source;
    }

    final tokens = const TagTokenizer().tokenize(source);
    if (tokens.isEmpty) {
      return source;
    }

    var migrated = source;
    for (final token in tokens.reversed) {
      if (token.name != ContentBlock.legacyKey) {
        continue;
      }

      final nameEnd = token.startIndex + token.name.length + 1;
      migrated = migrated.replaceRange(
        token.startIndex,
        nameEnd,
        '@${ContentBlock.key}',
      );
    }

    return migrated;
  }
}
