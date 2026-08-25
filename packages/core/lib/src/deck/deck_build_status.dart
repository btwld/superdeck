import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'deck_build_status.ack.dart';
part 'deck_build_status.g.dart';

enum DeckBuildPhase { unknown, building, success, failure }

@AckModel(additionalProperties: AckAdditionalPropertiesMode.discard)
final class DeckBuildError with _$DeckBuildErrorAck {
  final String message;

  const DeckBuildError({required this.message});

  static final fromJson = DeckBuildErrorSchema.fromJson;

  static DeckBuildError? fromObject(Object? value) =>
      DeckBuildErrorSchema.safeParse(value).getOrNull();
}

@AckModel(additionalProperties: AckAdditionalPropertiesMode.discard)
final class DeckBuildStatus with _$DeckBuildStatusAck {
  @JsonKey(name: 'status')
  final DeckBuildPhase phase;
  final DateTime timestamp;
  final int? slideCount;
  final DeckBuildError? error;

  DeckBuildStatus({
    required this.phase,
    required DateTime timestamp,
    this.slideCount,
    this.error,
  }) : timestamp = timestamp.toUtc();

  static final fromJson = DeckBuildStatusSchema.fromJson;

  static DeckBuildStatus? fromObject(Object? value) =>
      DeckBuildStatusSchema.safeParse(value).getOrNull();
}
