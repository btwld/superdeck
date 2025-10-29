import 'dart:collection';

/// Enumerates the possible states of a build recorded in `build_status.json`.
enum BuildStatusType { building, success, failure, unknown }

/// Base representation of a build status entry.
///
/// Concrete status implementations extend this sealed class to provide
/// type-specific helpers while sharing serialization and comparison logic.
sealed class BuildStatus {
  BuildStatus._({
    required DateTime timestamp,
    this.slideCount,
    Map<String, dynamic>? error,
  }) : timestamp = _normalizeTimestamp(timestamp),
       error = _normalizeError(error);

  /// Moment the status entry was generated. Always stored in UTC.
  final DateTime timestamp;

  /// Number of slides produced by the build, if known.
  final int? slideCount;

  /// Optional error payload populated for failure statuses.
  final Map<String, dynamic>? error;

  /// Convenience accessor for status comparisons.
  BuildStatusType get type;

  /// True when the build is currently running.
  bool get isBuilding => type == BuildStatusType.building;

  /// Serializes the status into the canonical `build_status.json` structure.
  Map<String, dynamic> toJson() {
    return {
      'status': type.name,
      'timestamp': timestamp.toUtc().toIso8601String(),
      if (slideCount != null) 'slideCount': slideCount,
      if (error != null && error!.isNotEmpty) 'error': error,
    };
  }

  /// Converts a JSON map into a typed [BuildStatus].
  ///
  /// Throws [FormatException] when required fields are missing or invalid.
  static BuildStatus fromJson(Map<String, dynamic> json) {
    final timestamp = _parseTimestamp(json['timestamp']);
    final slideCount = _parseSlideCount(json['slideCount']);
    final error = _parseError(json['error']);
    final status = (json['status'] as String?)?.toLowerCase();

    return switch (status) {
      'building' => BuildStatusBuilding(
        timestamp: timestamp,
        slideCount: slideCount,
      ),
      'success' => BuildStatusSuccess(
        timestamp: timestamp,
        slideCount: slideCount,
      ),
      'failure' => BuildStatusFailure(
        timestamp: timestamp,
        slideCount: slideCount,
        error: error,
      ),
      'unknown' => BuildStatusUnknown(
        timestamp: timestamp,
        slideCount: slideCount,
        error: error,
      ),
      null => BuildStatusUnknown(
        timestamp: timestamp,
        slideCount: slideCount,
        error: error,
      ),
      _ => BuildStatusUnknown(
        timestamp: timestamp,
        slideCount: slideCount,
        error: error,
      ),
    };
  }

  /// Creates a `building` status with the current timestamp by default.
  factory BuildStatus.building({DateTime? timestamp, int? slideCount}) {
    return BuildStatusBuilding(
      timestamp: timestamp ?? DateTime.now().toUtc(),
      slideCount: slideCount,
    );
  }

  /// Creates a `success` status with optional slide count metadata.
  factory BuildStatus.success({DateTime? timestamp, int? slideCount}) {
    return BuildStatusSuccess(
      timestamp: timestamp ?? DateTime.now().toUtc(),
      slideCount: slideCount,
    );
  }

  /// Creates a `failure` status and captures error context.
  factory BuildStatus.failure({
    DateTime? timestamp,
    int? slideCount,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? errorPayload,
  }) {
    return BuildStatusFailure(
      timestamp: timestamp ?? DateTime.now().toUtc(),
      slideCount: slideCount,
      error: errorPayload ?? _errorPayloadFrom(error, stackTrace),
    );
  }

  /// Creates an `unknown` status, useful for bootstrap scenarios.
  factory BuildStatus.unknown({
    DateTime? timestamp,
    int? slideCount,
    Map<String, dynamic>? error,
  }) {
    return BuildStatusUnknown(
      timestamp: timestamp ?? DateTime.now().toUtc(),
      slideCount: slideCount,
      error: error,
    );
  }

  /// Whether this status is more recent than [other].
  bool isNewerThan(BuildStatus? other) {
    if (other == null) return true;
    if (timestamp.isAfter(other.timestamp)) return true;
    if (timestamp.isAtSameMomentAs(other.timestamp)) return true;
    return false;
  }

  static DateTime _normalizeTimestamp(DateTime timestamp) {
    return timestamp.isUtc ? timestamp : timestamp.toUtc();
  }

  static Map<String, dynamic>? _normalizeError(Map<String, dynamic>? error) {
    if (error == null || error.isEmpty) return null;
    return UnmodifiableMapView({...error});
  }

  static DateTime _parseTimestamp(Object? value) {
    if (value is String) {
      final parsed = DateTime.parse(value);
      return _normalizeTimestamp(parsed);
    }

    throw const FormatException('Missing required field: timestamp');
  }

  static int? _parseSlideCount(Object? value) {
    return switch (value) {
      final num count => count.toInt(),
      _ => null,
    };
  }

  static Map<String, dynamic>? _parseError(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(
        value.map((key, entryValue) => MapEntry(key.toString(), entryValue)),
      );
    }

    return null;
  }

  static Map<String, dynamic>? _errorPayloadFrom(
    Object? error,
    StackTrace? stackTrace,
  ) {
    if (error == null) return null;

    return {
      'type': error.runtimeType.toString(),
      'message': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    };
  }
}

/// Status emitted while a build is in progress.
final class BuildStatusBuilding extends BuildStatus {
  BuildStatusBuilding({required super.timestamp, super.slideCount}) : super._();

  @override
  BuildStatusType get type => BuildStatusType.building;
}

/// Status emitted when a build completes successfully.
final class BuildStatusSuccess extends BuildStatus {
  BuildStatusSuccess({required super.timestamp, super.slideCount}) : super._();

  @override
  BuildStatusType get type => BuildStatusType.success;
}

/// Status emitted when a build fails.
final class BuildStatusFailure extends BuildStatus {
  BuildStatusFailure({required super.timestamp, super.slideCount, super.error})
    : super._();

  @override
  BuildStatusType get type => BuildStatusType.failure;
}

/// Status emitted when the current build state cannot be determined.
final class BuildStatusUnknown extends BuildStatus {
  BuildStatusUnknown({required super.timestamp, super.slideCount, super.error})
    : super._();

  @override
  BuildStatusType get type => BuildStatusType.unknown;
}
