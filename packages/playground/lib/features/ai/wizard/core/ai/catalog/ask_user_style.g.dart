// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ask_user_style.dart';

// **************************************************************************
// AckJsonSerializableGenerator
// **************************************************************************

AskUserStyle _$AskUserStyleFromJson(Map<String, dynamic> json) => AskUserStyle(
  question: AskUserStyle._ackFromRuntimeQuestion(json['question']),
  description: AskUserStyle._ackFromRuntimeDescription(json['description']),
  themeIds: AskUserStyle._ackFromRuntimeThemeIds(json['themeIds']),
  action: AskUserStyle._ackFromRuntimeAction(json['action']),
);

Map<String, dynamic> _$AskUserStyleToJson(
  AskUserStyle instance,
) => <String, dynamic>{
  'question': AskUserStyle._ackToRuntimeQuestion(instance.question),
  'description': ?AskUserStyle._ackToRuntimeDescription(instance.description),
  'themeIds': AskUserStyle._ackToRuntimeThemeIds(instance.themeIds),
  'action': AskUserStyle._ackToRuntimeAction(instance.action),
};
