// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ask_user_checkbox.dart';

// **************************************************************************
// AckJsonSerializableGenerator
// **************************************************************************

AskUserCheckbox _$AskUserCheckboxFromJson(Map<String, dynamic> json) =>
    AskUserCheckbox(
      question: AskUserCheckbox._ackFromRuntimeQuestion(json['question']),
      description: AskUserCheckbox._ackFromRuntimeDescription(
        json['description'],
      ),
      items: AskUserCheckbox._ackFromRuntimeItems(json['items']),
      selectedItems: AskUserCheckbox._ackFromRuntimeSelectedItems(
        json['selectedItems'],
      ),
      minSelections: AskUserCheckbox._ackFromRuntimeMinSelections(
        json['minSelections'],
      ),
      maxSelections: AskUserCheckbox._ackFromRuntimeMaxSelections(
        json['maxSelections'],
      ),
      action: AskUserCheckbox._ackFromRuntimeAction(json['action']),
    );

Map<String, dynamic> _$AskUserCheckboxToJson(AskUserCheckbox instance) =>
    <String, dynamic>{
      'question': AskUserCheckbox._ackToRuntimeQuestion(instance.question),
      'description': ?AskUserCheckbox._ackToRuntimeDescription(
        instance.description,
      ),
      'items': AskUserCheckbox._ackToRuntimeItems(instance.items),
      'selectedItems': ?AskUserCheckbox._ackToRuntimeSelectedItems(
        instance.selectedItems,
      ),
      'minSelections': ?AskUserCheckbox._ackToRuntimeMinSelections(
        instance.minSelections,
      ),
      'maxSelections': ?AskUserCheckbox._ackToRuntimeMaxSelections(
        instance.maxSelections,
      ),
      'action': AskUserCheckbox._ackToRuntimeAction(instance.action),
    };
