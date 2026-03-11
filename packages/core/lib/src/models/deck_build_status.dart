import 'package:dart_mappable/dart_mappable.dart';

part 'deck_build_status.mapper.dart';

@MappableEnum()
enum DeckBuildPhase {
  unknown,
  building,
  success,
  failure;

  String get wireValue {
    return switch (this) {
      DeckBuildPhase.unknown => 'unknown',
      DeckBuildPhase.building => 'building',
      DeckBuildPhase.success => 'success',
      DeckBuildPhase.failure => 'failure',
    };
  }

  static DeckBuildPhase fromWireValue(Object? value) {
    return switch (value) {
      'building' => DeckBuildPhase.building,
      'success' => DeckBuildPhase.success,
      'failure' => DeckBuildPhase.failure,
      _ => DeckBuildPhase.unknown,
    };
  }
}

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

  Map<String, Object?> toMap() {
    return {
      'type': type,
      'message': message,
      if (stackTrace != null) 'stackTrace': stackTrace,
    };
  }

  static DeckBuildError fromMap(Map<String, Object?> map) {
    return DeckBuildErrorMapper.fromMap(map.cast<String, dynamic>());
  }

  static DeckBuildError? fromObject(Object? value) {
    if (value is! Map) {
      return null;
    }

    final map = Map<String, Object?>.from(value);
    final type = map['type'];
    final message = map['message'];
    final stackTrace = map['stackTrace'];

    if (type is! String || message is! String) {
      return null;
    }

    try {
      return fromMap({
        'type': type,
        'message': message,
        if (stackTrace is String) 'stackTrace': stackTrace,
      });
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

  Map<String, Object?> toMap() {
    return {
      'status': phase.wireValue,
      'timestamp': timestamp.toIso8601String(),
      if (slideCount != null) 'slideCount': slideCount,
      if (error != null) 'error': error!.toMap(),
    };
  }

  static DeckBuildStatus fromMap(Map<String, Object?> map) {
    return DeckBuildStatusMapper.fromMap(map.cast<String, dynamic>());
  }

  static DeckBuildStatus? fromObject(Object? value) {
    if (value is! Map) {
      return null;
    }

    final map = Map<String, Object?>.from(value);

    final timestampRaw = map['timestamp'];
    if (timestampRaw is! String) {
      return null;
    }

    final timestamp = DateTime.tryParse(timestampRaw);
    if (timestamp == null) {
      return null;
    }

    final slideCountRaw = map['slideCount'];
    final slideCount = slideCountRaw is int ? slideCountRaw : null;

    final parsedError = DeckBuildError.fromObject(map['error']);

    try {
      return fromMap({
        'status': DeckBuildPhase.fromWireValue(map['status']).name,
        'timestamp': timestamp.toIso8601String(),
        if (slideCount != null) 'slideCount': slideCount,
        if (parsedError != null) 'error': parsedError.toMap(),
      });
    } on Object {
      return null;
    }
  }
}
