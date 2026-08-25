// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'ask_user_radio.dart';

// **************************************************************************
// AckJsonSerializableGenerator
// **************************************************************************

InputOption _$InputOptionFromJson(Map<String, dynamic> json) => InputOption(
  title: InputOption._ackFromRuntimeTitle(json['title']),
  description: InputOption._ackFromRuntimeDescription(json['description']),
  icon: InputOption._ackFromRuntimeIcon(json['icon']),
);

Map<String, dynamic> _$InputOptionToJson(
  InputOption instance,
) => <String, dynamic>{
  'title': InputOption._ackToRuntimeTitle(instance.title),
  'description': ?InputOption._ackToRuntimeDescription(instance.description),
  'icon': ?InputOption._ackToRuntimeIcon(instance.icon),
};

AskUserRadio _$AskUserRadioFromJson(Map<String, dynamic> json) => AskUserRadio(
  question: AskUserRadio._ackFromRuntimeQuestion(json['question']),
  description: AskUserRadio._ackFromRuntimeDescription(json['description']),
  options: AskUserRadio._ackFromRuntimeOptions(json['options']),
  action: AskUserRadio._ackFromRuntimeAction(json['action']),
);

Map<String, dynamic> _$AskUserRadioToJson(
  AskUserRadio instance,
) => <String, dynamic>{
  'question': AskUserRadio._ackToRuntimeQuestion(instance.question),
  'description': ?AskUserRadio._ackToRuntimeDescription(instance.description),
  'options': AskUserRadio._ackToRuntimeOptions(instance.options),
  'action': AskUserRadio._ackToRuntimeAction(instance.action),
};
