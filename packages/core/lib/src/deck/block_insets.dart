import 'package:ack/ack.dart';
import 'package:dart_mappable/dart_mappable.dart';

part 'block_insets.mapper.dart';

String _authoringMessage(String field) =>
    '$field must use a finite non-negative scalar, a non-empty object with '
    'horizontal and/or vertical, or a non-empty object with top, right, '
    'bottom, and/or left. Symmetric and physical-edge keys cannot be mixed.';

const _symmetricKeys = {'horizontal', 'vertical'};
const _edgeKeys = {'top', 'right', 'bottom', 'left'};

final _insetValueSchema = Ack.number().min(0).finite();

final _symmetricInsetsSchema = Ack.object(
  {
    'horizontal': _insetValueSchema.optional(),
    'vertical': _insetValueSchema.optional(),
  },
  additionalProperties: false,
).withConstraint(const _NonEmptyInsetsObjectConstraint());

final _partialEdgeInsetsSchema = Ack.object(
  {
    'top': _insetValueSchema.optional(),
    'right': _insetValueSchema.optional(),
    'bottom': _insetValueSchema.optional(),
    'left': _insetValueSchema.optional(),
  },
  additionalProperties: false,
).withConstraint(const _NonEmptyInsetsObjectConstraint());

/// Four normalized physical inset edges for a slide block.
///
/// Used for both block `padding` and block `margin`. Authoring shorthand
/// (scalar, symmetric, or partial physical edges) is normalized by
/// [parseAuthoring]; compiled contracts only carry the normalized
/// four-edge form validated by [schema].
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

  /// Normalized contract schema: a closed object with all four physical edges.
  static final schema = Ack.object({
    'top': _insetValueSchema,
    'right': _insetValueSchema,
    'bottom': _insetValueSchema,
    'left': _insetValueSchema,
  }, additionalProperties: false);

  /// Authoring schema: scalar, symmetric map, or physical-edge map.
  static final authoringSchema = Ack.anyOf([
    _insetValueSchema,
    _symmetricInsetsSchema,
    _partialEdgeInsetsSchema,
  ]);

  static final fromMap = BlockInsetsMapper.fromMap;

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
