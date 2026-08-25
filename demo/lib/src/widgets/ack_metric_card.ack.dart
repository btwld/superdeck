// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'ack_metric_card.dart';

// **************************************************************************
// AckModelGenerator
// **************************************************************************

/// Immutable model generated from `ackMetricCardArgsSchema`.
@AckInfer.jsonSerializable
final class AckMetricCardArgs {
  AckMetricCardArgs({
    required this.label,
    required this.value,
    this.caption,
    this.tone,
  });

  factory AckMetricCardArgs.parse(Object? input) {
    return $ack.parse(input);
  }

  factory AckMetricCardArgs.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final String label;

  final String value;

  final String? caption;

  final String? tone;

  static final $ack = AckModelAdapter(
    schema: () => ackMetricCardArgsSchema,
    fromRuntime: AckMetricCardArgs._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  static SchemaResult<AckMetricCardArgs> safeParse(Object? input) =>
      $ack.safeParse(input);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  AckMetricCardArgs copyWith({
    String? label,
    String? value,
    String? caption,
    String? tone,
  }) => AckMetricCardArgs(
    label: label ?? this.label,
    value: value ?? this.value,
    caption: caption ?? this.caption,
    tone: tone ?? this.tone,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AckMetricCardArgs &&
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
      'AckMetricCardArgs(label: $label, value: $value, caption: $caption, tone: $tone)';

  static AckMetricCardArgs _fromAckRuntime(Map<String, Object?> value) =>
      _$AckMetricCardArgsFromJson(Map<String, dynamic>.from(value));

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    ..._$AckMetricCardArgsToJson(this),
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
