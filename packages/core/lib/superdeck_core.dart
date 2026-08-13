/// Rendering primitives, Markdown parsing, and schema validation for SuperDeck.
library;

export 'package:ack/ack.dart';

// Cache
export 'src/cache/asset_cache_store.dart';
export 'src/cache/asset_cache_store_io.dart';
// Presentation
export 'src/deck/block_insets.dart';
export 'src/deck/block_model.dart';
export 'src/deck/deck_build_status.dart';
export 'src/deck/deck_build_store.dart';
export 'src/deck/deck_workspace.dart';
export 'src/deck/deck_format_exception.dart';
export 'src/deck/deck_loader.dart';
export 'src/deck/slide_contract.dart';
export 'src/deck/slide_model.dart';
// Markdown
export 'src/markdown/hero_tag_helpers.dart';
// Only the line-oriented view is shared across packages; the offset-based
// range API has a single in-package consumer (TagTokenizer).
export 'src/markdown/markdown_fences.dart' show fencedCodeLines;
export 'src/markdown/markdown_syntaxes.dart';
export 'src/markdown/tag_tokenizer.dart';
// Plugins
export 'src/plugins/deck_plugin.dart';
// Utils
export 'src/utils/extensions.dart';
export 'src/utils/file_watcher.dart';
export 'src/utils/generate_hash.dart';
export 'src/utils/yaml_utils.dart';
