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

final class DeckBuildError {
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

  static DeckBuildError? fromObject(Object? value) {
    if (value is! Map<String, Object?>) {
      return null;
    }

    final type = value['type'];
    final message = value['message'];

    if (type is! String || message is! String) {
      return null;
    }

    final stackTrace = value['stackTrace'];
    return DeckBuildError(
      type: type,
      message: message,
      stackTrace: stackTrace is String ? stackTrace : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeckBuildError &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          message == other.message &&
          stackTrace == other.stackTrace;

  @override
  int get hashCode => Object.hash(type, message, stackTrace);
}

final class DeckBuildStatus {
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

  static DeckBuildStatus? fromObject(Object? value) {
    if (value is! Map<String, Object?>) {
      return null;
    }

    final timestampRaw = value['timestamp'];
    if (timestampRaw is! String) {
      return null;
    }

    final timestamp = DateTime.tryParse(timestampRaw);
    if (timestamp == null) {
      return null;
    }

    final slideCountRaw = value['slideCount'];
    final slideCount = slideCountRaw is int ? slideCountRaw : null;

    return DeckBuildStatus(
      phase: DeckBuildPhase.fromWireValue(value['status']),
      timestamp: timestamp,
      slideCount: slideCount,
      error: DeckBuildError.fromObject(value['error']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeckBuildStatus &&
          runtimeType == other.runtimeType &&
          phase == other.phase &&
          timestamp == other.timestamp &&
          slideCount == other.slideCount &&
          error == other.error;

  @override
  int get hashCode => Object.hash(phase, timestamp, slideCount, error);
}
