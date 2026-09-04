// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'ask_user_slider.dart';

// **************************************************************************
// AckJsonSerializableGenerator
// **************************************************************************

AskUserSlider _$AskUserSliderFromJson(
  Map<String, dynamic> json,
) => AskUserSlider(
  question: AskUserSlider._ackFromRuntimeQuestion(json['question']),
  description: AskUserSlider._ackFromRuntimeDescription(json['description']),
  minValue: AskUserSlider._ackFromRuntimeMinValue(json['minValue']),
  maxValue: AskUserSlider._ackFromRuntimeMaxValue(json['maxValue']),
  defaultValue: AskUserSlider._ackFromRuntimeDefaultValue(json['defaultValue']),
  unit: AskUserSlider._ackFromRuntimeUnit(json['unit']),
  action: AskUserSlider._ackFromRuntimeAction(json['action']),
);

Map<String, dynamic> _$AskUserSliderToJson(
  AskUserSlider instance,
) => <String, dynamic>{
  'question': AskUserSlider._ackToRuntimeQuestion(instance.question),
  'description': ?AskUserSlider._ackToRuntimeDescription(instance.description),
  'minValue': AskUserSlider._ackToRuntimeMinValue(instance.minValue),
  'maxValue': AskUserSlider._ackToRuntimeMaxValue(instance.maxValue),
  'defaultValue': AskUserSlider._ackToRuntimeDefaultValue(
    instance.defaultValue,
  ),
  'unit': ?AskUserSlider._ackToRuntimeUnit(instance.unit),
  'action': AskUserSlider._ackToRuntimeAction(instance.action),
};
