// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'deck_build_status.dart';

// **************************************************************************
// AckJsonSerializableGenerator
// **************************************************************************

DeckBuildError _$DeckBuildErrorFromJson(Map<String, dynamic> json) =>
    DeckBuildError(
      message: _ackDeckBuildErrorFromRuntimeMessage(json['message']),
    );

Map<String, dynamic> _$DeckBuildErrorToJson(DeckBuildError instance) =>
    <String, dynamic>{
      'message': _ackDeckBuildErrorToRuntimeMessage(instance.message),
    };

DeckBuildStatus _$DeckBuildStatusFromJson(Map<String, dynamic> json) =>
    DeckBuildStatus(
      phase: _ackDeckBuildStatusFromRuntimePhase(json['status']),
      timestamp: _ackDeckBuildStatusFromRuntimeTimestamp(json['timestamp']),
      slideCount: _ackDeckBuildStatusFromRuntimeSlideCount(json['slideCount']),
      error: _ackDeckBuildStatusFromRuntimeError(json['error']),
    );

Map<String, dynamic> _$DeckBuildStatusToJson(
  DeckBuildStatus instance,
) => <String, dynamic>{
  'status': _ackDeckBuildStatusToRuntimePhase(instance.phase),
  'timestamp': _ackDeckBuildStatusToRuntimeTimestamp(instance.timestamp),
  'slideCount': ?_ackDeckBuildStatusToRuntimeSlideCount(instance.slideCount),
  'error': ?_ackDeckBuildStatusToRuntimeError(instance.error),
};
