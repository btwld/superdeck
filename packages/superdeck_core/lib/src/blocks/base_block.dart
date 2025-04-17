// Base block library for all blocks
library blocks;

import 'package:dart_mappable/dart_mappable.dart';
import 'package:superdeck_core/superdeck_core.dart'
    hide DartPadTheme, ImageFit, ContentAlignment;

part 'base_block.mapper.dart';

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

  static final schema = ackEnum(values);
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

  static final schema = ackEnum(values);
}

@MappableEnum()
enum DartPadTheme {
  darkMode,
  lightMode;

  static final schema = ackEnum(values);
}

@MappableClass(
  discriminatorKey: 'type',
)
abstract class BaseBlock with BaseBlockMappable {
  final String type;
  final ContentAlignment? align;
  final int? flex;
  final bool? scrollable;

  BaseBlock({
    required this.type,
    this.align,
    this.flex,
    this.scrollable,
  });

  // Keep the base schema definition here
  static final schema = Ack.object(
    {
      'type': Ack.string,
      'align': ContentAlignment.schema.nullable(),
      'flex': Ack.int.nullable(),
      'scrollable': Ack.boolean.nullable(),
    },
    required: [
      "type",
    ],
  );

  // Keep the base parse method
  static BaseBlock parse(Map<String, dynamic> map) {
    schema.validateOrThrow(map);
    // Note: The generated Mapper name might change based on the file name
    return BaseBlockMapper.fromMap(map);
  }

  // Update discriminated schema to use new class names and keys
  static final DiscriminatedObjectSchema discriminatedSchema =
      Ack.discriminated(
    discriminatorKey: 'type',
    schemas: {
      'column': schema,
      'dartpad': schema,
      'widget': schema,
      'image': schema,
      'section': schema,
    },
  );
}
