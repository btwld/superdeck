// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'ack_metric_card.dart';

// **************************************************************************
// AckModelGenerator
// **************************************************************************

final class _MetricCardArgsCopyWithUnset {
  const _MetricCardArgsCopyWithUnset();
}

/// Immutable model generated from `metricCardArgsSchema`.
@AckInfer.jsonSerializable
final class MetricCardArgs {
  MetricCardArgs({
    required this.label,
    required this.value,
    this.caption,
    this.tone,
  });

  factory MetricCardArgs.parse(Object? input) {
    return $ack.parse(input);
  }

  factory MetricCardArgs.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  static const _MetricCardArgsCopyWithUnset _ackCopyWithUnset =
      _MetricCardArgsCopyWithUnset();

  final String label;

  final String value;

  final String? caption;

  final String? tone;

  static final $ack = AckModelAdapter(
    schema: () => metricCardArgsSchema,
    fromRuntime: MetricCardArgs._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  static SchemaResult<MetricCardArgs> safeParse(Object? input) =>
      $ack.safeParse(input);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  MetricCardArgs copyWith({
    String? label,
    String? value,
    Object? caption = _ackCopyWithUnset,
    Object? tone = _ackCopyWithUnset,
  }) => MetricCardArgs(
    label: label ?? this.label,
    value: value ?? this.value,
    caption: identical(caption, _ackCopyWithUnset)
        ? this.caption
        : caption as String?,
    tone: identical(tone, _ackCopyWithUnset) ? this.tone : tone as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetricCardArgs &&
          runtimeType == other.runtimeType &&
          deepEquals(label, other.label) &&
          deepEquals(value, other.value) &&
          deepEquals(caption, other.caption) &&
          deepEquals(tone, other.tone));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(label),
    deepHashCode(value),
    deepHashCode(caption),
    deepHashCode(tone),
  ]);

  @override
  String toString() =>
      'MetricCardArgs(label: $label, value: $value, caption: $caption, tone: $tone)';

  static MetricCardArgs _fromAckRuntime(Map<String, Object?> value) =>
      _$MetricCardArgsFromJson(Map<String, dynamic>.from(value));

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    ..._$MetricCardArgsToJson(this),
  };

  static String _ackFromRuntimeLabel(Object? value) => value as String;

  static Object? _ackToRuntimeLabel(String value) => value;

  static String _ackFromRuntimeValue(Object? value) => value as String;

  static Object? _ackToRuntimeValue(String value) => value;

  static String? _ackFromRuntimeCaption(Object? value) => value as String?;

  static Object? _ackToRuntimeCaption(String? value) => value;

  static String? _ackFromRuntimeTone(Object? value) => value as String?;

  static Object? _ackToRuntimeTone(String? value) => value;
}
