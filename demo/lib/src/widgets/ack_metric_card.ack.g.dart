// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'ack_metric_card.dart';

// **************************************************************************
// AckJsonSerializableGenerator
// **************************************************************************

MetricCardArgs _$MetricCardArgsFromJson(Map<String, dynamic> json) =>
    MetricCardArgs(
      label: MetricCardArgs._ackFromRuntimeLabel(json['label']),
      value: MetricCardArgs._ackFromRuntimeValue(json['value']),
      caption: MetricCardArgs._ackFromRuntimeCaption(json['caption']),
      tone: MetricCardArgs._ackFromRuntimeTone(json['tone']),
    );

Map<String, dynamic> _$MetricCardArgsToJson(MetricCardArgs instance) =>
    <String, dynamic>{
      'label': MetricCardArgs._ackToRuntimeLabel(instance.label),
      'value': MetricCardArgs._ackToRuntimeValue(instance.value),
      'caption': ?MetricCardArgs._ackToRuntimeCaption(instance.caption),
      'tone': ?MetricCardArgs._ackToRuntimeTone(instance.tone),
    };
