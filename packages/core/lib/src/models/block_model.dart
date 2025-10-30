import 'package:collection/collection.dart';
import 'package:superdeck_core/superdeck_core.dart';

/// Base class for all content blocks in a slide.
///
/// Blocks are the fundamental building units of slide content. They can be
/// arranged in sections and support alignment, flexible sizing, and scrolling.
sealed class Block {
  /// The type identifier for this block.
  final String type;

  /// The alignment of content within this block.
  final ContentAlignment? align;

  /// The flex weight for this block when in a flexible layout.
  final int flex;

  /// Whether this block's content is scrollable.
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
    'align': ContentAlignment.schema.nullable().optional(),
    'flex': Ack.string().nullable().optional(),
    'scrollable': Ack.boolean().nullable().optional(),
  }, additionalProperties: true);

  /// Parses a block from a JSON map.
  ///
  /// Automatically determines the block type from the discriminator key.
  static Block parse(Map<String, dynamic> map) {
    discriminatedSchema.parse(map);
    return fromMap(map);
  }

  /// Schema for discriminated union of block types.
  static final discriminatedSchema = Ack.discriminated(
    discriminatorKey: 'type',
    schemas: {
      ContentBlock.key: ContentBlock.schema,
      WidgetBlock.key: WidgetBlock.schema,
    },
  );

  Map<String, dynamic> toMap();
  Block copyWith({ContentAlignment? align, int? flex, bool? scrollable});

  static Block fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String;
    return switch (type) {
      SectionBlock.key => SectionBlock.fromMap(map),
      ContentBlock.key => ContentBlock.fromMap(map),
      WidgetBlock.key => WidgetBlock.fromMap(map),
      _ => throw ArgumentError('Unknown block type: $type'),
    };
  }

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;
}

/// A block that contains multiple child blocks arranged horizontally.
///
/// Sections are used to create multi-column layouts within a slide.
class SectionBlock extends Block {
  /// The child blocks contained in this section.
  final List<Block> blocks;

  /// The type identifier for section blocks.
  static const key = 'section';

  SectionBlock(List<Block>? blocks, {super.align, super.flex, super.scrollable})
    : blocks = blocks ?? [],
      super(type: key);

  /// The total flex value of all child blocks.
  int get totalBlockFlex {
    return blocks.fold(0, (total, block) => total + block.flex);
  }

  @override
  SectionBlock copyWith({
    List<Block>? blocks,
    ContentAlignment? align,
    int? flex,
    bool? scrollable,
  }) {
    return SectionBlock(
      blocks ?? this.blocks,
      align: align ?? this.align,
      flex: flex ?? this.flex,
      scrollable: scrollable ?? this.scrollable,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      if (align != null) 'align': align!.name,
      'flex': flex,
      'scrollable': scrollable,
      if (blocks.isNotEmpty) 'blocks': blocks.map((b) => b.toMap()).toList(),
    };
  }

  static SectionBlock fromMap(Map<String, dynamic> map) {
    return SectionBlock(
      (map['blocks'] as List<dynamic>?)
          ?.map((e) => Block.fromMap(e as Map<String, dynamic>))
          .toList(),
      align: map['align'] != null
          ? ContentAlignment.fromJson(map['align'] as String)
          : null,
      flex: (map['flex'] as num?)?.toInt() ?? 1,
      scrollable: map['scrollable'] as bool? ?? false,
    );
  }

  /// Parses a section block from a JSON map.
  static SectionBlock parse(Map<String, dynamic> map) {
    schema.parse(map);
    return fromMap(map);
  }

  /// Creates a section block with a single text column.
  static SectionBlock text(String content) {
    return SectionBlock([ContentBlock(content)]);
  }

  /// Validation schema for section blocks.
  static final schema = Ack.object({
    'type': Ack.string(),
    'align': ContentAlignment.schema.nullable().optional(),
    'flex': Ack.string().nullable().optional(),
    'scrollable': Ack.boolean().nullable().optional(),
    'blocks': Ack.list(Ack.object({})).nullable().optional(),
  }, additionalProperties: true);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectionBlock &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          align == other.align &&
          flex == other.flex &&
          scrollable == other.scrollable &&
          const DeepCollectionEquality().equals(blocks, other.blocks);

  @override
  int get hashCode => Object.hash(
    type,
    align,
    flex,
    scrollable,
    const DeepCollectionEquality().hash(blocks),
  );
}

/// A block that displays markdown content.
///
/// This is the most common block type, used for text and markdown content.
class ContentBlock extends Block {
  /// The type identifier for content blocks.
  /// TODO: Change to 'block' in next major version
  static const key = 'column';

  /// The markdown content to display.
  final String content;

  ContentBlock(String? content, {super.align, super.flex, super.scrollable})
    : content = content ?? '',
      super(type: key);

  @override
  ContentBlock copyWith({
    String? content,
    ContentAlignment? align,
    int? flex,
    bool? scrollable,
  }) {
    return ContentBlock(
      content ?? this.content,
      align: align ?? this.align,
      flex: flex ?? this.flex,
      scrollable: scrollable ?? this.scrollable,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      if (align != null) 'align': align!.name,
      'flex': flex,
      'scrollable': scrollable,
      if (content.isNotEmpty) 'content': content,
    };
  }

  static ContentBlock fromMap(Map<String, dynamic> map) {
    try {
      return ContentBlock(
        map['content'] as String?,
        align: map['align'] != null
            ? ContentAlignment.fromJson(map['align'] as String)
            : null,
        flex: (map['flex'] as num?)?.toInt() ?? 1,
        scrollable: map['scrollable'] as bool? ?? false,
      );
    } catch (e) {
      throw Exception('Failed to parse ContentBlock: $e');
    }
  }

  static final schema = Ack.object({
    'type': Ack.string(),
    'align': ContentAlignment.schema.nullable().optional(),
    'flex': Ack.string().nullable().optional(),
    'scrollable': Ack.boolean().nullable().optional(),
    'content': Ack.string().nullable().optional(),
  }, additionalProperties: true);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentBlock &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          align == other.align &&
          flex == other.flex &&
          scrollable == other.scrollable &&
          content == other.content;

  @override
  int get hashCode => Object.hash(type, align, flex, scrollable, content);
}

enum DartPadTheme {
  dark,
  light;

  static final schema = ackEnum(values);

  String toJson() => name;

  static DartPadTheme fromJson(String value) {
    // Support both camelCase and snake_case (though this enum is all lowercase)
    final normalized = value.replaceAll('_', '');
    return DartPadTheme.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized.toLowerCase(),
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

  static final schema = ackEnum(values);

  String toJson() => name;

  static ImageFit fromJson(String value) {
    // Support both camelCase and snake_case
    final normalized = value.replaceAll('_', '');
    return ImageFit.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized.toLowerCase(),
      orElse: () => throw ArgumentError('Invalid ImageFit: $value'),
    );
  }
}

class WidgetBlock extends Block {
  static const key = 'widget';
  final Map<String, dynamic> args;
  final String name;

  WidgetBlock({
    required this.name,
    Map<String, dynamic>? args,
    super.align,
    super.flex,
    super.scrollable,
  }) : args = args == null ? const {} : Map.unmodifiable(args),
       super(type: key);

  @override
  WidgetBlock copyWith({
    String? name,
    Map<String, dynamic>? args,
    ContentAlignment? align,
    int? flex,
    bool? scrollable,
  }) {
    return WidgetBlock(
      name: name ?? this.name,
      args: args ?? this.args,
      align: align ?? this.align,
      flex: flex ?? this.flex,
      scrollable: scrollable ?? this.scrollable,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      if (align != null) 'align': align!.name,
      'flex': flex,
      'scrollable': scrollable,
      'name': name,
      ...args, // Unmapped properties hook: spread args into the map
    };
  }

  static WidgetBlock fromMap(Map<String, dynamic> map) {
    // Extract known fields
    final name = map['name'] as String;
    final align = map['align'] != null
        ? ContentAlignment.fromJson(map['align'] as String)
        : null;
    final flex = (map['flex'] as num?)?.toInt() ?? 1;
    final scrollable = map['scrollable'] as bool? ?? false;

    // Everything else goes into args (implementing UnmappedPropertiesHook behavior)
    final args = Map<String, dynamic>.from(map);
    args.remove('type');
    args.remove('align');
    args.remove('flex');
    args.remove('scrollable');
    args.remove('name');

    return WidgetBlock(
      name: name,
      args: args,
      align: align,
      flex: flex,
      scrollable: scrollable,
    );
  }

  static final schema = Ack.object({
    'type': Ack.string(),
    'align': ContentAlignment.schema.nullable().optional(),
    'flex': Ack.string().nullable().optional(),
    'scrollable': Ack.boolean().nullable().optional(),
    "name": Ack.string(),
  }, additionalProperties: true);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetBlock &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          align == other.align &&
          flex == other.flex &&
          scrollable == other.scrollable &&
          name == other.name &&
          const MapEquality().equals(args, other.args);

  @override
  int get hashCode => Object.hash(
    type,
    align,
    flex,
    scrollable,
    name,
    const MapEquality().hash(args),
  );
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

  static final schema = ackEnum(values);

  String toJson() => name;

  static ContentAlignment fromJson(String value) {
    // Support both camelCase and snake_case
    final normalized = value.replaceAll('_', '');
    return ContentAlignment.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized.toLowerCase(),
      orElse: () => throw ArgumentError('Invalid ContentAlignment: $value'),
    );
  }
}

extension StringContentExt on String {
  ContentBlock toBlock() => ContentBlock(this);
}

extension BlockExt on Block {
  Block flex(int flex) => copyWith(flex: flex);
  Block scrollable([bool scrollable = true]) =>
      copyWith(scrollable: scrollable);
}
