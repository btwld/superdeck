import 'package:dart_mappable/dart_mappable.dart';

part 'deck_build_status.mapper.dart';

@MappableEnum()
enum DeckBuildPhase { unknown, building, success, failure }

@MappableClass()
final class DeckBuildError with DeckBuildErrorMappable {
  final String message;

  const DeckBuildError({required this.message});

  static final fromMap = DeckBuildErrorMapper.fromMap;

  static DeckBuildError? fromObject(Object? value) {
    if (value is! Map) return null;
    try {
      return DeckBuildErrorMapper.fromMap(Map<String, dynamic>.from(value));
    } on Object {
      return null;
    }
  }
}

@MappableClass()
final class DeckBuildStatus with DeckBuildStatusMappable {
  @MappableField(key: 'status')
  final DeckBuildPhase phase;
  final DateTime timestamp;
  final int? slideCount;
  final DeckBuildError? error;

  const DeckBuildStatus({
    required this.phase,
    required this.timestamp,
    this.slideCount,
    this.error,
  });

  static final fromMap = DeckBuildStatusMapper.fromMap;

  static DeckBuildStatus? fromObject(Object? value) {
    if (value is! Map) return null;
    try {
      return DeckBuildStatusMapper.fromMap(Map<String, dynamic>.from(value));
    } on Object {
      return null;
    }
  }
}
