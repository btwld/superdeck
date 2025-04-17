library superdeck_core;

export 'package:ack/ack.dart';

export 'src/assets/asset.repository.dart';
// New Exports based on feature structure
export 'src/assets/models/asset.model.dart';
export 'src/assets/models/source.model.dart';
// Export individual block files instead of block.dart
export 'src/blocks/base_block.dart';
export 'src/blocks/dartpad_block.dart';
export 'src/blocks/image_block.dart';
export 'src/blocks/markdown_block.dart';
export 'src/blocks/section_block.dart';
export 'src/blocks/widget_block.dart';
export 'src/common/extensions.dart';
export 'src/common/hash.dart';
export 'src/common/json_formatter.dart';
export 'src/common/mappers.dart';
export 'src/common/uuid.dart';
export 'src/common/watcher.dart';
export 'src/presentation/models/presentation.model.dart';
// Updated Presentation exports
export 'src/presentation/models/presentation_config.model.dart';
export 'src/presentation/models/slide.model.dart';
export 'src/presentation/presentation.repository.dart';
// export 'src/presentation/parser.dart'; // Add when created
