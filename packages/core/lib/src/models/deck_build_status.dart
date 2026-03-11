import 'package:dart_mappable/dart_mappable.dart';

part 'deck_build_status.mapper.dart';

@MappableEnum()
enum DeckBuildPhase { unknown, building, success, failure }

@MappableClass()
final class DeckBuildError with DeckBuildErrorMappable {
  final String type;
  final String message;
  final String? stackTrace;

  const DeckBuildError({
    required this.type,
    required this.message,
    this.stackTrace,
  });

  Map<String, dynamic> toMap() {
    return DeckBuildErrorMapper.ensureInitialized().encodeMap(this);
  }

  static DeckBuildError fromMap(Map<String, dynamic> map) {
    return DeckBuildErrorMapper.fromMap(map);
  }

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

  Map<String, dynamic> toMap() {
    return DeckBuildStatusMapper.ensureInitialized().encodeMap(this);
  }

  static DeckBuildStatus fromMap(Map<String, dynamic> map) {
    return DeckBuildStatusMapper.fromMap(map);
  }

  static DeckBuildStatus? fromObject(Object? value) {
    if (value is! Map) return null;
    try {
      return DeckBuildStatusMapper.fromMap(Map<String, dynamic>.from(value));
    } on Object {
      return null;
    }
  }
}
