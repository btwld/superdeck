// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'ack_metric_card.dart';

// **************************************************************************
// AckJsonSerializableGenerator
// **************************************************************************

AckMetricCardArgs _$AckMetricCardArgsFromJson(Map<String, dynamic> json) =>
    AckMetricCardArgs(
      label: AckMetricCardArgs._ackFromRuntimeLabel(json['label']),
      value: AckMetricCardArgs._ackFromRuntimeValue(json['value']),
      caption: AckMetricCardArgs._ackFromRuntimeCaption(json['caption']),
      tone: AckMetricCardArgs._ackFromRuntimeTone(json['tone']),
    );

Map<String, dynamic> _$AckMetricCardArgsToJson(AckMetricCardArgs instance) =>
    <String, dynamic>{
      'label': AckMetricCardArgs._ackToRuntimeLabel(instance.label),
      'value': AckMetricCardArgs._ackToRuntimeValue(instance.value),
      'caption': ?AckMetricCardArgs._ackToRuntimeCaption(instance.caption),
      'tone': ?AckMetricCardArgs._ackToRuntimeTone(instance.tone),
    };
