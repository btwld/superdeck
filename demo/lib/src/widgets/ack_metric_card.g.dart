// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'ack_metric_card.dart';

/// Extension type for AckMetricCardArgs
extension type AckMetricCardArgsType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static AckMetricCardArgsType parse(Object? data) {
    return ackMetricCardArgsSchema.parseAs(
      data,
      (validated) => AckMetricCardArgsType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<AckMetricCardArgsType> safeParse(Object? data) {
    return ackMetricCardArgsSchema.safeParseAs(
      data,
      (validated) => AckMetricCardArgsType(validated as Map<String, Object?>),
    );
  }

  String get label => _data['label'] as String;

  String get value => _data['value'] as String;

  String? get caption => _data['caption'] as String?;

  String? get tone => _data['tone'] as String?;
}
