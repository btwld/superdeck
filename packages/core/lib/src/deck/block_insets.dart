import 'package:ack/ack.dart';
import 'package:dart_mappable/dart_mappable.dart';

part 'block_insets.mapper.dart';

const _paddingAuthoringMessage =
    'Padding must use a finite non-negative scalar, a non-empty object with '
    'horizontal and/or vertical, or a non-empty object with top, right, '
    'bottom, and/or left. Symmetric and physical-edge keys cannot be mixed.';

final _paddingValueSchema = Ack.number().min(0).finite();

final _symmetricPaddingSchema = Ack.object(
  {
    'horizontal': _paddingValueSchema.optional(),
    'vertical': _paddingValueSchema.optional(),
  },
  additionalProperties: false,
).withConstraint(const _NonEmptyPaddingObjectConstraint());

final _edgePaddingSchema = Ack.object(
  {
    'top': _paddingValueSchema.optional(),
    'right': _paddingValueSchema.optional(),
    'bottom': _paddingValueSchema.optional(),
    'left': _paddingValueSchema.optional(),
  },
  additionalProperties: false,
).withConstraint(const _NonEmptyPaddingObjectConstraint());

/// Four normalized physical padding edges for a slide block.
@MappableClass()
final class BlockInsets with BlockInsetsMappable {
  final double top;
  final double right;
  final double bottom;
  final double left;

  BlockInsets({
    double top = 0,
    double right = 0,
    double bottom = 0,
    double left = 0,
  }) : top = _validateEdge(top, 'top'),
       right = _validateEdge(right, 'right'),
       bottom = _validateEdge(bottom, 'bottom'),
       left = _validateEdge(left, 'left');

  BlockInsets.all(double value)
    : this(top: value, right: value, bottom: value, left: value);

  BlockInsets.symmetric({double horizontal = 0, double vertical = 0})
    : this(
        top: vertical,
        right: horizontal,
        bottom: vertical,
        left: horizontal,
      );

  static final schema = Ack.anyOf([
    _paddingValueSchema,
    _symmetricPaddingSchema,
    _edgePaddingSchema,
  ]);

  static final fromMap = BlockInsetsMapper.fromMap;

  /// Parses one supported authoring form and normalizes it to physical edges.
  static BlockInsets parse(Object? value) {
    if (!schema.safeParse(value).isOk) {
      throw ArgumentError.value(value, 'padding', _paddingAuthoringMessage);
    }

    if (value is num) {
      return BlockInsets.all(value.toDouble());
    }

    final map = Map<String, Object?>.from(value! as Map);
    if (map.containsKey('horizontal') || map.containsKey('vertical')) {
      return BlockInsets.symmetric(
        horizontal: _readEdge(map, 'horizontal'),
        vertical: _readEdge(map, 'vertical'),
      );
    }

    return BlockInsets(
      top: _readEdge(map, 'top'),
      right: _readEdge(map, 'right'),
      bottom: _readEdge(map, 'bottom'),
      left: _readEdge(map, 'left'),
    );
  }

  static double _readEdge(Map<String, Object?> map, String key) {
    return (map[key] as num?)?.toDouble() ?? 0;
  }

  static double _validateEdge(double value, String edge) {
    if (value.isFinite && value >= 0) return value;
    throw ArgumentError.value(
      value,
      'padding.$edge',
      'Padding edges must be finite non-negative numbers.',
    );
  }
}

final class _NonEmptyPaddingObjectConstraint
    extends Constraint<Map<String, Object?>>
    with Validator<Map<String, Object?>>, JsonSchemaSpec<Map<String, Object?>> {
  const _NonEmptyPaddingObjectConstraint()
    : super(
        constraintKey: 'padding_non_empty_object',
        description: 'Padding objects must contain at least one property.',
      );

  @override
  String buildMessage(Map<String, Object?> value) {
    return 'Padding objects must contain at least one property.';
  }

  @override
  bool isValid(Map<String, Object?> value) => value.isNotEmpty;

  @override
  Map<String, Object?> toJsonSchema() => const {'minProperties': 1};
}
