// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ask_user_image_style.dart';

// **************************************************************************
// AckJsonSerializableGenerator
// **************************************************************************

AskUserImageStyle _$AskUserImageStyleFromJson(Map<String, dynamic> json) =>
    AskUserImageStyle(
      question: AskUserImageStyle._ackFromRuntimeQuestion(json['question']),
      description: AskUserImageStyle._ackFromRuntimeDescription(
        json['description'],
      ),
      action: AskUserImageStyle._ackFromRuntimeAction(json['action']),
    );

Map<String, dynamic> _$AskUserImageStyleToJson(AskUserImageStyle instance) =>
    <String, dynamic>{
      'question': AskUserImageStyle._ackToRuntimeQuestion(instance.question),
      'description': ?AskUserImageStyle._ackToRuntimeDescription(
        instance.description,
      ),
      'action': AskUserImageStyle._ackToRuntimeAction(instance.action),
    };
