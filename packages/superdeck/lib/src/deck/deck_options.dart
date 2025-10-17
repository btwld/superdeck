import 'package:flutter/widgets.dart';

import '../rendering/slides/slide_parts.dart';
import '../styling/styles.dart';

class DeckOptions {
  final SlideStyle? baseStyle;
  final Map<String, SlideStyle> styles;
  final Map<String, WidgetBlockBuilder> widgets;
  final SlideParts parts;
  final bool debug;

  const DeckOptions({
    this.baseStyle,
    this.styles = const <String, SlideStyle>{},
    this.widgets = const <String, WidgetBlockBuilder>{},
    this.parts = const SlideParts(),
    this.debug = false,
  });

  DeckOptions copyWith({
    SlideStyle? baseStyle,
    Map<String, SlideStyle>? styles,
    Map<String, WidgetBlockBuilder>? widgets,
    SlideParts? parts,
    bool? debug,
  }) {
    return DeckOptions(
      baseStyle: baseStyle ?? this.baseStyle,
      styles: styles ?? this.styles,
      widgets: widgets ?? this.widgets,
      parts: parts ?? this.parts,
      debug: debug ?? this.debug,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeckOptions &&
          runtimeType == other.runtimeType &&
          baseStyle == other.baseStyle &&
          styles == other.styles &&
          widgets == other.widgets &&
          parts == other.parts &&
          debug == other.debug;

  @override
  int get hashCode => Object.hash(baseStyle, styles, widgets, parts, debug);
}

typedef WidgetBlockBuilder = Widget Function(WidgetArgs args);

/// A type-safe wrapper around `Map<String, dynamic>` for widget arguments.
///
/// Provides convenient getter methods with automatic type conversion
/// and validation for widget configuration parameters.
class WidgetArgs implements Map<String, dynamic> {
  final Map<String, dynamic> _data;

  /// Creates a new WidgetArgs instance wrapping the provided data.
  const WidgetArgs(this._data);

  /// Creates a WidgetArgs from a `Map<String, dynamic>`.
  factory WidgetArgs.from(Map<String, dynamic> map) => WidgetArgs(map);

  // Type-safe getters with automatic conversion

  /// Gets a String value for the given key.
  /// Throws ArgumentError if key is not found or cannot be converted.
  String getString(String key) => _getAs<String>(key);

  /// Gets an int value for the given key.
  /// Throws ArgumentError if key is not found or cannot be converted.
  int getInt(String key) => _getAs<int>(key);

  /// Gets a double value for the given key.
  /// Throws ArgumentError if key is not found or cannot be converted.
  double getDouble(String key) => _getAs<double>(key);

  /// Gets a bool value for the given key.
  /// Throws ArgumentError if key is not found or cannot be converted.
  bool getBool(String key) => _getAs<bool>(key);

  // Nullable variants

  /// Gets a String value for the given key, or null if not found/convertible.
  String? getStringOrNull(String key) => _getMaybeAs<String>(key);

  /// Gets an int value for the given key, or null if not found/convertible.
  int? getIntOrNull(String key) => _getMaybeAs<int>(key);

  /// Gets a double value for the given key, or null if not found/convertible.
  double? getDoubleOrNull(String key) => _getMaybeAs<double>(key);

  /// Gets a bool value for the given key, or null if not found/convertible.
  bool? getBoolOrNull(String key) => _getMaybeAs<bool>(key);

  // Getters with default values

  /// Gets a String value for the given key, or returns the default value.
  String getStringOr(String key, String defaultValue) =>
      getStringOrNull(key) ?? defaultValue;

  /// Gets an int value for the given key, or returns the default value.
  int getIntOr(String key, int defaultValue) =>
      getIntOrNull(key) ?? defaultValue;

  /// Gets a double value for the given key, or returns the default value.
  double getDoubleOr(String key, double defaultValue) =>
      getDoubleOrNull(key) ?? defaultValue;

  /// Gets a bool value for the given key, or returns the default value.
  bool getBoolOr(String key, bool defaultValue) =>
      getBoolOrNull(key) ?? defaultValue;

  // Advanced getters

  /// Gets a `List<String>` for the given key, or an empty list if not found.
  List<String> getStringList(String key) {
    final value = _data[key];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return <String>[];
  }

  /// Gets nested WidgetArgs for the given key, or null if not found.
  WidgetArgs? getNested(String key) {
    final value = _data[key];
    return value is Map<String, dynamic> ? WidgetArgs(value) : null;
  }

  // Validation

  /// Checks if all required keys are present in the arguments.
  bool hasRequired(List<String> keys) =>
      keys.every((key) => _data.containsKey(key));

  /// Validates that all required keys are present, throws if not.
  void requireKeys(List<String> keys) {
    final missing = keys.where((key) => !_data.containsKey(key)).toList();
    if (missing.isNotEmpty) {
      throw ArgumentError('Missing required keys: ${missing.join(', ')}');
    }
  }

  // Map interface implementation

  @override
  dynamic operator [](Object? key) => _data[key];

  @override
  void operator []=(String key, dynamic value) => _data[key] = value;

  @override
  void addAll(Map<String, dynamic> other) => _data.addAll(other);

  @override
  void addEntries(Iterable<MapEntry<String, dynamic>> newEntries) =>
      _data.addEntries(newEntries);

  @override
  Map<RK, RV> cast<RK, RV>() => _data.cast<RK, RV>();

  @override
  void clear() => _data.clear();

  @override
  bool containsKey(Object? key) => _data.containsKey(key);

  @override
  bool containsValue(Object? value) => _data.containsValue(value);

  @override
  Iterable<MapEntry<String, dynamic>> get entries => _data.entries;

  @override
  void forEach(void Function(String key, dynamic value) action) =>
      _data.forEach(action);

  @override
  bool get isEmpty => _data.isEmpty;

  @override
  bool get isNotEmpty => _data.isNotEmpty;

  @override
  Iterable<String> get keys => _data.keys;

  @override
  int get length => _data.length;

  @override
  Map<K2, V2> map<K2, V2>(
    MapEntry<K2, V2> Function(String key, dynamic value) convert,
  ) => _data.map(convert);

  @override
  dynamic putIfAbsent(String key, dynamic Function() ifAbsent) =>
      _data.putIfAbsent(key, ifAbsent);

  @override
  dynamic remove(Object? key) => _data.remove(key);

  @override
  void removeWhere(bool Function(String key, dynamic value) test) =>
      _data.removeWhere(test);

  @override
  dynamic update(
    String key,
    dynamic Function(dynamic value) update, {
    dynamic Function()? ifAbsent,
  }) => _data.update(key, update, ifAbsent: ifAbsent);

  @override
  void updateAll(dynamic Function(String key, dynamic value) update) =>
      _data.updateAll(update);

  @override
  Iterable<dynamic> get values => _data.values;

  // Internal helper methods

  /// Returns the value for [key] converted to type [T], or `null` if the conversion fails.
  T? _getMaybeAs<T>(String key) {
    final value = _data[key];
    if (value == null) return null;
    if (value is T) return value;

    if (T == int) {
      if (value is num) return value.toInt() as T;
      if (value is String) return int.tryParse(value) as T?;
    } else if (T == double) {
      if (value is num) return value.toDouble() as T;
      if (value is String) return double.tryParse(value) as T?;
    } else if (T == bool) {
      if (value is String) {
        final lower = value.toLowerCase();
        if (lower == 'true') return true as T;
        if (lower == 'false') return false as T;
      }
    } else if (T == String) {
      return value.toString() as T;
    }

    return null;
  }

  /// Returns the value for [key] converted to type [T].
  /// Throws ArgumentError if the key is not found or conversion fails.
  T _getAs<T>(String key) {
    final value = _getMaybeAs<T>(key);
    if (value == null) {
      throw ArgumentError(
        'Key "$key" not found or cannot be converted to ${T.toString()}.',
      );
    }
    return value;
  }

  @override
  String toString() => 'WidgetArgs($_data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetArgs &&
          runtimeType == other.runtimeType &&
          _data == other._data;

  @override
  int get hashCode => _data.hashCode;
}
