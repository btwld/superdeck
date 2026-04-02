import 'package:ack/ack.dart';
import 'package:dart_mappable/dart_mappable.dart';

part 'block_model.mapper.dart';

/// Base class for all content blocks in a slide.
///
/// Blocks are the fundamental building units of slide content. They can be
/// arranged in sections and support alignment, flexible sizing, and scrolling.
@MappableClass(discriminatorKey: 'type', ignoreNull: true)
sealed class Block with BlockMappable {
  final String type;
  final ContentAlignment? align;
  final int flex;
  final bool scrollable;

  Block({
    required this.type,
    this.align,
    this.flex = 1,
    this.scrollable = false,
  });

  /// Base schema for all block types
  static final schema = Ack.object({
    'type': Ack.string(),
    'align': ContentAlignment.schema.optional(),
    'flex': Ack.integer().optional(),
    'scrollable': Ack.boolean().optional(),
  }, additionalProperties: true);

  /// Parses a block from a JSON map.
  ///
  /// Automatically determines the block type from the discriminator key.
  static Block parse(Map<String, Object?> map) =>
      fromMap(discriminatedSchema.parse(map)!);

  /// Schema for discriminated union of block types.
  ///
  /// Note: SectionBlock is intentionally not included here as it is a container
  /// for discriminated blocks, not a discriminated type itself.
  static final discriminatedSchema = Ack.discriminated(
    discriminatorKey: 'type',
    schemas: {
      ContentBlock.key: ContentBlock.schema,
      WidgetBlock.key: WidgetBlock.schema,
    },
  );

  static final fromMap = BlockMapper.fromMap;
}

/// A block that contains multiple child blocks arranged horizontally.
///
/// Sections are used to create multi-column layouts within a slide.
@MappableClass(discriminatorValue: SectionBlock.key)
class SectionBlock extends Block with SectionBlockMappable {
  final List<Block> blocks;

  static const key = 'section';

  SectionBlock(List<Block>? blocks, {super.align, super.flex, super.scrollable})
    : blocks = List.unmodifiable(blocks ?? const []),
      super(type: key);

  /// The total flex value of all child blocks.
  int get totalBlockFlex {
    return blocks.fold(0, (total, block) => total + block.flex);
  }

  static final fromMap = SectionBlockMapper.fromMap;

  /// Parses a section block from a JSON map.
  static SectionBlock parse(Map<String, Object?> map) =>
      fromMap(schema.parse(map)!);

  /// Creates a section block with a single text block.
  static SectionBlock text(String content) {
    return SectionBlock([ContentBlock(content)]);
  }

  /// Validation schema for section blocks.
  static final schema = Ack.object({
    'align': ContentAlignment.schema.optional(),
    'flex': Ack.integer().optional(),
    'scrollable': Ack.boolean().optional(),
    'blocks': Ack.list(Block.discriminatedSchema).optional(),
  }, additionalProperties: true);
}

/// Alias used by generated Ack model schemas for [SectionBlock] references.
final sectionBlockSchema = SectionBlock.schema;

/// A block that displays markdown content.
///
/// This is the most common block type, used for text and markdown content.
@MappableClass(discriminatorValue: ContentBlock.key)
class ContentBlock extends Block with ContentBlockMappable {
  static const key = 'block';

  final String content;

  ContentBlock(String? content, {super.align, super.flex, super.scrollable})
    : content = content ?? '',
      super(type: key);

  static final fromMap = ContentBlockMapper.fromMap;

  /// Validation schema for content blocks.
  static final schema = Ack.object({
    'type': Ack.literal(key).optional(),
    'align': ContentAlignment.schema.optional(),
    'flex': Ack.integer().optional(),
    'scrollable': Ack.boolean().optional(),
    'content': Ack.string().optional(),
  }, additionalProperties: true);

  /// Parses a content block from a JSON map with schema validation.
  static ContentBlock parse(Map<String, Object?> map) =>
      fromMap(schema.parse(map)!);
}

@MappableEnum()
enum DartPadTheme {
  dark,
  light;

  static final schema = Ack.enumValues(values);

  String toJson() => name;

  static DartPadTheme fromJson(Object value) {
    if (value is DartPadTheme) return value;
    if (value is! String) {
      throw ArgumentError('Invalid DartPadTheme: $value');
    }
    final normalized = value.toLowerCase();
    return DartPadTheme.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => throw ArgumentError('Invalid DartPadTheme: $value'),
    );
  }
}

@MappableEnum()
enum ImageFit {
  fill,
  contain,
  cover,
  fitWidth,
  fitHeight,
  none,
  scaleDown;

  static final schema = Ack.enumValues(values);

  String toJson() => name;

  static ImageFit fromJson(Object value) {
    if (value is ImageFit) return value;
    if (value is! String) {
      throw ArgumentError('Invalid ImageFit: $value');
    }
    final normalized = value.toLowerCase();
    return ImageFit.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => throw ArgumentError('Invalid ImageFit: $value'),
    );
  }
}

@MappableClass(
  discriminatorValue: WidgetBlock.key,
  hook: UnmappedPropertiesHook('args'),
)
class WidgetBlock extends Block with WidgetBlockMappable {
  static const key = 'widget';
  static const _reservedKeys = {'name', 'align', 'flex', 'scrollable'};

  final Map<String, Object?> args;
  final String name;

  WidgetBlock({
    required this.name,
    Map<String, Object?>? args,
    super.align,
    super.flex,
    super.scrollable,
  }) : args = _validateArgs(args),
       super(type: key);

  static Map<String, Object?> _validateArgs(Map<String, Object?>? args) {
    if (args == null) return const {};

    // Single pass: strip the 'type' discriminator key leaked by
    // UnmappedPropertiesHook during deserialization, and reject any
    // other reserved keys that indicate a caller mistake.
    final filtered = <String, Object?>{};
    final collisions = <String>[];

    for (final entry in args.entries) {
      if (entry.key == 'type') continue;
      if (_reservedKeys.contains(entry.key)) {
        collisions.add(entry.key);
      } else {
        filtered[entry.key] = entry.value;
      }
    }

    if (collisions.isNotEmpty) {
      throw ArgumentError(
        'args must not contain reserved keys: ${collisions.join(', ')}',
      );
    }
    return Map.unmodifiable(filtered);
  }

  static final fromMap = WidgetBlockMapper.fromMap;

  static final schema = Ack.object({
    'align': ContentAlignment.schema.optional(),
    'flex': Ack.integer().optional(),
    'scrollable': Ack.boolean().optional(),
    'name': Ack.string(),
  }, additionalProperties: true);

  /// Parses a widget block from a JSON map with schema validation.
  static WidgetBlock parse(Map<String, Object?> map) =>
      fromMap(schema.parse(map)!);
}

@MappableEnum()
enum ContentAlignment {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight;

  static final schema = Ack.enumValues(values);

  String toJson() => name;

  static ContentAlignment fromJson(Object value) {
    if (value is ContentAlignment) return value;
    if (value is! String) {
      throw ArgumentError('Invalid ContentAlignment: $value');
    }
    final normalized = value.toLowerCase();
    return ContentAlignment.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => throw ArgumentError('Invalid ContentAlignment: $value'),
    );
  }
}
