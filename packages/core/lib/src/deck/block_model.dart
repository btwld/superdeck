import 'package:ack/ack.dart';
import 'package:dart_mappable/dart_mappable.dart';

import 'block_insets.dart';

part 'block_model.mapper.dart';

final _positiveFlexSchema = Ack.integer().positive();
final _nonNegativeFiniteNumberSchema = Ack.number().min(0).finite();

int _validateFlex(int flex) {
  if (flex > 0) return flex;
  throw ArgumentError.value(
    flex,
    'flex',
    'Flex must be an integer greater than zero.',
  );
}

double _validateSpacing(double spacing) {
  if (spacing.isFinite && spacing >= 0) return spacing;
  throw ArgumentError.value(
    spacing,
    'spacing',
    'Spacing must be a finite number greater than or equal to zero.',
  );
}

void _validateFlexInput(Map<String, Object?> map) {
  if (map['flex'] case final int flex) {
    _validateFlex(flex);
  }
}

void _validateSpacingInput(Map<String, Object?> map) {
  if (map['spacing'] case final num spacing) {
    _validateSpacing(spacing.toDouble());
  }
}

Map<String, Object?> _normalizeBlockInput(Map<String, Object?> map) {
  if (!map.containsKey('padding')) return map;
  final padding = BlockInsets.parse(map['padding']);
  return {...map, 'padding': padding.toMap()};
}

/// Base class for renderable blocks in a slide section.
///
/// Blocks are leaf content units inside sections. They support alignment,
/// flexible sizing, and scrolling.
@MappableClass(discriminatorKey: 'type', ignoreNull: true)
sealed class Block with BlockMappable {
  final String type;
  final ContentAlignment? align;
  final int flex;
  final BlockInsets? padding;
  final bool scrollable;

  Block({
    required this.type,
    this.align,
    int flex = 1,
    this.padding,
    this.scrollable = false,
  }) : flex = _validateFlex(flex);

  /// Base schema for all block types
  static final schema = Ack.object({
    'type': Ack.string(),
    'align': ContentAlignment.schema.optional(),
    'flex': _positiveFlexSchema.optional(),
    'padding': BlockInsets.schema.optional(),
    'scrollable': Ack.boolean().optional(),
  }, additionalProperties: true);

  /// Parses a block from a JSON map.
  ///
  /// Automatically determines the block type from the discriminator key.
  static Block parse(Map<String, Object?> map) {
    final normalized = _normalizeBlockInput(map);
    _validateFlexInput(normalized);
    return fromMap(discriminatedSchema.parse(normalized)!);
  }

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

  /// The effective alignment when no section context is available.
  ///
  /// Section renderers must use [SectionBlock.resolveBlockAlign] so section
  /// alignment can be inherited. When [align] is not set explicitly, this
  /// block-only fallback defaults to
  /// [ContentAlignment.centerLeft] because paragraph-like content is easier
  /// to read and scan when left-aligned. Set `align: center` explicitly to
  /// restore the previous default.
  ContentAlignment get resolvedAlign => align ?? ContentAlignment.centerLeft;
}

/// A section that contains multiple child blocks arranged horizontally.
///
/// Sections are used to create multi-column layouts within a slide.
@MappableClass(ignoreNull: true)
class SectionBlock with SectionBlockMappable {
  final List<Block> blocks;
  final ContentAlignment? align;
  final int flex;
  final double spacing;
  final String type;

  static const key = 'section';

  SectionBlock(
    List<Block>? blocks, {
    this.align,
    int flex = 1,
    double spacing = 0,
    String type = key,
  }) : blocks = List.unmodifiable(blocks ?? const []),
       flex = _validateFlex(flex),
       spacing = _validateSpacing(spacing),
       type = _validateType(type);

  /// The total flex value of all child blocks.
  int get totalBlockFlex {
    return blocks.fold(0, (total, block) => total + block.flex);
  }

  /// Resolves a child's alignment in section context.
  ///
  /// Explicit block alignment wins, followed by section alignment, then the
  /// platform-neutral [ContentAlignment.centerLeft] default.
  ContentAlignment resolveBlockAlign(Block block) {
    return block.align ?? align ?? ContentAlignment.centerLeft;
  }

  static final fromMap = SectionBlockMapper.fromMap;

  /// Parses a section block from a JSON map.
  static SectionBlock parse(Map<String, Object?> map) {
    _validateFlexInput(map);
    _validateSpacingInput(map);
    return fromMap(schema.parse(map)!);
  }

  /// Creates a section block with a single text block.
  static SectionBlock text(String content) {
    return SectionBlock([ContentBlock(content)]);
  }

  static String _validateType(String type) {
    if (type == key) return type;
    throw ArgumentError.value(type, 'type', 'SectionBlock type must be "$key"');
  }

  /// Validation schema for section blocks.
  static final schema = Ack.object({
    'type': Ack.literal(key).optional(),
    'align': ContentAlignment.schema.optional(),
    'flex': _positiveFlexSchema.optional(),
    'spacing': _nonNegativeFiniteNumberSchema.optional(),
    'blocks': Ack.list(Block.discriminatedSchema).optional(),
  }, additionalProperties: false);
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

  ContentBlock(
    String? content, {
    super.align,
    super.flex,
    super.padding,
    super.scrollable,
  }) : content = content ?? '',
       super(type: key);

  static final fromMap = ContentBlockMapper.fromMap;

  /// Validation schema for content blocks.
  static final schema = Ack.object({
    'type': Ack.literal(key).optional(),
    'align': ContentAlignment.schema.optional(),
    'flex': _positiveFlexSchema.optional(),
    'padding': BlockInsets.schema.optional(),
    'scrollable': Ack.boolean().optional(),
    'content': Ack.string().optional(),
  }, additionalProperties: true);

  /// Parses a content block from a JSON map with schema validation.
  static ContentBlock parse(Map<String, Object?> map) {
    final normalized = _normalizeBlockInput(map);
    _validateFlexInput(normalized);
    return fromMap(schema.parse(normalized)!);
  }
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
  static const _reservedKeys = {
    'name',
    'align',
    'flex',
    'padding',
    'scrollable',
  };

  final Map<String, Object?> args;
  final String name;

  WidgetBlock({
    required this.name,
    Map<String, Object?>? args,
    super.align,
    super.flex,
    super.padding,
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
    'flex': _positiveFlexSchema.optional(),
    'padding': BlockInsets.schema.optional(),
    'scrollable': Ack.boolean().optional(),
    'name': Ack.string(),
  }, additionalProperties: true);

  /// Parses a widget block from a JSON map with schema validation.
  static WidgetBlock parse(Map<String, Object?> map) {
    final normalized = _normalizeBlockInput(map);
    _validateFlexInput(normalized);
    return fromMap(schema.parse(normalized)!);
  }
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
