import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'block_insets.ack.dart';
part 'block_insets.ack.g.dart';

String _authoringMessage(String field) =>
    '$field must use a finite non-negative scalar, a non-empty object with '
    'horizontal and/or vertical, or a non-empty object with top, right, '
    'bottom, and/or left. Symmetric and physical-edge keys cannot be mixed.';

const _symmetricKeys = {'horizontal', 'vertical'};
const _edgeKeys = {'top', 'right', 'bottom', 'left'};

final _authoringInsetValueSchema = Ack.number().min(0).finite();

AckSchema<num, double> _normalizedInsetValueSchema() =>
    _authoringInsetValueSchema.codec<double>(
      decode: (value) => value.toDouble(),
      encode: (value) => value,
    );

final _symmetricInsetsSchema = Ack.object(
  {
    'horizontal': _authoringInsetValueSchema.optional(),
    'vertical': _authoringInsetValueSchema.optional(),
  },
  additionalProperties: false,
).withConstraint(const _NonEmptyInsetsObjectConstraint());

final _partialEdgeInsetsSchema = Ack.object(
  {
    'top': _authoringInsetValueSchema.optional(),
    'right': _authoringInsetValueSchema.optional(),
    'bottom': _authoringInsetValueSchema.optional(),
    'left': _authoringInsetValueSchema.optional(),
  },
  additionalProperties: false,
).withConstraint(const _NonEmptyInsetsObjectConstraint());

/// Four normalized physical inset edges for a slide block.
///
/// Used for both block `padding` and block `margin`. Authoring shorthand
/// (scalar, symmetric, or partial physical edges) is normalized by
/// [parseAuthoring]; compiled contracts only carry the normalized
/// four-edge form validated by [BlockInsetsSchema.schema].
@AckModel()
final class BlockInsets with _$BlockInsetsAck {
  @AckField(
    schema: _normalizedInsetValueSchema,
    presence: AckFieldPresence.required,
  )
  final double top;

  @AckField(
    schema: _normalizedInsetValueSchema,
    presence: AckFieldPresence.required,
  )
  final double right;

  @AckField(
    schema: _normalizedInsetValueSchema,
    presence: AckFieldPresence.required,
  )
  final double bottom;

  @AckField(
    schema: _normalizedInsetValueSchema,
    presence: AckFieldPresence.required,
  )
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

  /// Authoring schema: scalar, symmetric map, or physical-edge map.
  static final authoringSchema = Ack.anyOf([
    _authoringInsetValueSchema,
    _symmetricInsetsSchema,
    _partialEdgeInsetsSchema,
  ]);

  static final fromJson = BlockInsetsSchema.fromJson;

  /// Parses one supported authoring form and normalizes it to physical edges.
  ///
  /// [field] names the authored option (`padding` or `margin`) so errors
  /// report the exact field and edge, e.g. `margin.left`.
  static BlockInsets parseAuthoring(Object? value, {required String field}) {
    if (value is num) {
      return BlockInsets.all(_validateAuthoringValue(value, field));
    }

    if (value is Map) {
      final map = <String, Object?>{
        for (final entry in value.entries) '${entry.key}': entry.value,
      };
      final keys = map.keys.toSet();
      final isSymmetric = keys.isNotEmpty && _symmetricKeys.containsAll(keys);
      final isEdges = keys.isNotEmpty && _edgeKeys.containsAll(keys);
      if (!isSymmetric && !isEdges) {
        throw ArgumentError.value(value, field, _authoringMessage(field));
      }

      double read(String key) {
        if (!map.containsKey(key)) return 0;
        final edgeValue = map[key];

        return _validateAuthoringValue(edgeValue, '$field.$key');
      }

      if (isSymmetric) {
        return BlockInsets.symmetric(
          horizontal: read('horizontal'),
          vertical: read('vertical'),
        );
      }

      return BlockInsets(
        top: read('top'),
        right: read('right'),
        bottom: read('bottom'),
        left: read('left'),
      );
    }

    throw ArgumentError.value(value, field, _authoringMessage(field));
  }

  static double _validateAuthoringValue(Object? value, String name) {
    if (value is num && value.isFinite && value >= 0) return value.toDouble();
    throw ArgumentError.value(
      value,
      name,
      'Inset values must be finite non-negative numbers.',
    );
  }

  static double _validateEdge(double value, String edge) {
    if (value.isFinite && value >= 0) return value;
    throw ArgumentError.value(
      value,
      edge,
      'Inset edges must be finite non-negative numbers.',
    );
  }
}

final class _NonEmptyInsetsObjectConstraint
    extends Constraint<Map<String, Object?>>
    with Validator<Map<String, Object?>>, JsonSchemaSpec<Map<String, Object?>> {
  const _NonEmptyInsetsObjectConstraint()
    : super(
        constraintKey: 'insets_non_empty_object',
        description: 'Inset objects must contain at least one property.',
      );

  @override
  String buildMessage(Map<String, Object?> value) {
    return 'Inset objects must contain at least one property.';
  }

  @override
  bool isValid(Map<String, Object?> value) => value.isNotEmpty;

  @override
  Map<String, Object?> toJsonSchema() => const {'minProperties': 1};
}
