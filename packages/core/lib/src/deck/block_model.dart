import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

import 'block_insets.dart';

part 'block_model.ack.dart';
part 'block_model.ack.g.dart';

/// Positive flex weight shared by the canonical block/section schemas and the
/// AI-generation projection in `slide_contract.dart`.
IntegerSchema positiveFlexSchema() => Ack.integer().positive();

/// Finite non-negative number shared by section `spacing` and the
/// AI-generation projection in `slide_contract.dart`.
AckSchema<num, double> nonNegativeSpacingSchema() => Ack.number()
    .min(0)
    .finite()
    .codec<double>(
      decode: (value) => value.toDouble(),
      encode: (value) => value,
    );

StringSchema _sectionTypeSchema() => Ack.literal(SectionBlock.key);

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

Map<String, Object?> _normalizeAuthoringInsets(Map<String, Object?> map) {
  var normalized = map;
  for (final field in const ['margin', 'padding']) {
    final value = normalized[field];
    if (value == null) continue;
    final insets = BlockInsets.parseAuthoring(value, field: field);
    normalized = {...normalized, field: insets.toJson()};
  }

  return normalized;
}

/// Base class for renderable blocks in a slide section.
///
/// Blocks are leaf content units inside sections. They support alignment,
/// flexible sizing, and scrolling.
@AckModel(discriminatorKey: 'type')
sealed class Block with _$BlockAck {
  String get type;

  final ContentAlignment? align;

  @AckField(schema: positiveFlexSchema)
  final int flex;
  final BlockInsets? margin;
  final BlockInsets? padding;
  final bool scrollable;

  Block({
    this.align,
    int flex = 1,
    this.margin,
    this.padding,
    this.scrollable = false,
  }) : flex = _validateFlex(flex);

  /// Parses a block from normalized contract data.
  ///
  /// Automatically determines the block type from the discriminator key.
  /// Insets must already be normalized physical edges; use [parseAuthoring]
  /// for Markdown directive input.
  static Block parse(Map<String, Object?> map) => BlockSchema.parse(map);

  /// Parses a block from authored directive options.
  ///
  /// Normalizes `margin` and `padding` shorthand (scalar, symmetric, or
  /// partial physical edges) before decoding through the contract schema.
  static Block parseAuthoring(Map<String, Object?> map) {
    return parse(_normalizeAuthoringInsets(map));
  }

  static final fromJson = BlockSchema.fromJson;
}

/// A section that contains multiple child blocks arranged horizontally.
///
/// Sections are used to create multi-column layouts within a slide.
@AckModel()
final class SectionBlock with _$SectionBlockAck {
  @AckField(presence: AckFieldPresence.optional)
  final List<Block> blocks;
  final ContentAlignment? align;

  @AckField(schema: positiveFlexSchema)
  final int flex;

  @AckField(schema: nonNegativeSpacingSchema)
  final double spacing;

  @AckField(schema: _sectionTypeSchema)
  final String type;

  static const key = 'section';

  SectionBlock(
    List<Block>? blocks, {
    this.align,
    int flex = 1,
    double spacing = 0,
    String type = 'section',
  }) : blocks = List.unmodifiable(blocks ?? const []),
       flex = _validateFlex(flex),
       spacing = _validateSpacing(spacing),
       type = _validateType(type);

  /// Resolves a child's alignment in section context.
  ///
  /// Explicit block alignment wins, followed by section alignment, then the
  /// platform-neutral [ContentAlignment.centerLeft] default.
  ContentAlignment resolveBlockAlign(Block block) {
    return block.align ?? align ?? ContentAlignment.centerLeft;
  }

  static final fromJson = SectionBlockSchema.fromJson;

  /// Parses a section block from a JSON map.
  static SectionBlock parse(Map<String, Object?> map) =>
      SectionBlockSchema.parse(map);

  /// Creates a section block with a single text block.
  static SectionBlock text(String content) {
    return SectionBlock([ContentBlock(content)]);
  }

  static String _validateType(String type) {
    if (type == key) return type;
    throw ArgumentError.value(type, 'type', 'SectionBlock type must be "$key"');
  }
}

/// A block that displays markdown content.
///
/// This is the most common block type, used for text and markdown content.
@AckModel(
  discriminatorValue: ContentBlock.key,
  unknownProperties: AckUnknownPropertyPolicy.reject,
)
final class ContentBlock extends Block with _$ContentBlockAck {
  static const key = 'block';

  @AckField(presence: AckFieldPresence.optional)
  final String content;

  ContentBlock(
    String? content, {
    super.align,
    super.flex,
    super.margin,
    super.padding,
    super.scrollable,
  }) : content = content ?? '',
       super();

  @override
  String get type => 'block';

  static final fromJson = ContentBlockSchema.fromJson;

  /// Parses a content block from normalized contract data.
  static ContentBlock parse(Map<String, Object?> map) =>
      ContentBlockSchema.parse(map);
}

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

@AckModel(
  discriminatorValue: WidgetBlock.key,
  unknownProperties: AckUnknownPropertyPolicy.capture,
  captureField: 'args',
)
final class WidgetBlock extends Block with _$WidgetBlockAck {
  static const key = 'widget';
  static const _reservedKeys = {
    'name',
    'align',
    'flex',
    'margin',
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
    super.margin,
    super.padding,
    super.scrollable,
  }) : args = _validateArgs(args),
       super();

  @override
  String get type => 'widget';

  static Map<String, Object?> _validateArgs(Map<String, Object?>? args) {
    if (args == null) return deepUnmodifiableJsonMap(const {});

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
    return deepUnmodifiableJsonMap(filtered);
  }

  static final fromJson = WidgetBlockSchema.fromJson;

  /// Parses a widget block from normalized contract data.
  static WidgetBlock parse(Map<String, Object?> map) =>
      WidgetBlockSchema.parse(map);
}

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
