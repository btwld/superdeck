import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/widgets.dart';

import '../../components/parts/slide_parts.dart';
import '../common/styles/style.dart';

part 'deck_options.mapper.dart';

@MappableClass()
class DeckOptions with DeckOptionsMappable {
  final DeckStyle baseStyle;
  final Map<String, DeckStyle> styles;
  final Map<String, WidgetBlockBuilder> widgets;
  final SlideParts parts;
  final bool debug;

  const DeckOptions({
    this.baseStyle = const DeckStyle(),
    this.styles = const <String, DeckStyle>{},
    this.widgets = const <String, WidgetBlockBuilder>{},
    this.parts = SlideParts.defaultParts,
    this.debug = false,
  });
}

typedef WidgetBlockBuilder = Widget Function(
  Map<String, dynamic> args,
);

extension MapExt on Map<String, dynamic> {
  String? getStringOrNull(String key) => _getMaybeAs<String>(key);

  int? getIntOrNull(String key) => _getMaybeAs<int>(key);

  double? getDoubleOrNull(String key) => _getMaybeAs<double>(key);

  bool? getBoolOrNull(String key) => _getMaybeAs<bool>(key);

  bool getBool(String key) => _getAs<bool>(key);

  int getInt(String key) => _getAs<int>(key);

  double getDouble(String key) => _getAs<double>(key);

  String getString(String key) => _getAs<String>(key);

  /// Returns the value for [key] converted to type [T], or `null` if the conversion fails.

  /// Returns the value for [key] converted to type [T], or `null` if the conversion fails.
  T? _getMaybeAs<T>(String key) {
    final value = this[key];
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

  T _getAs<T>(String key) {
    final value = _getMaybeAs<T>(key);
    if (value == null) {
      throw ArgumentError('Key "$key" not found in the map.');
    }
    return value;
  }
}
