import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../../../../core/domain/design/presentation_theme_catalog.dart';

/// Restricts theme ID fields in a component schema to one catalog instance.
Schema schemaWithPresentationThemeIds(
  Schema schema,
  PresentationThemeCatalog themeCatalog, {
  required List<List<String>> paths,
}) {
  final schemaMap = _copyJsonMap(schema.value);
  final themeIds = themeCatalog.currentThemes
      .map((theme) => theme.id)
      .toList(growable: false);

  for (final path in paths) {
    Map<String, Object?> current = schemaMap;
    for (final segment in path) {
      current = current[segment]! as Map<String, Object?>;
    }
    current['enum'] = themeIds;
  }

  return ObjectSchema.fromMap(schemaMap);
}

Map<String, Object?> _copyJsonMap(Map<String, Object?> source) {
  return {
    for (final MapEntry(:key, :value) in source.entries)
      key: switch (value) {
        Map<String, Object?> value => _copyJsonMap(value),
        Map value => _copyJsonMap(value.cast()),
        List value => value.map(_copyJsonValue).toList(),
        _ => value,
      },
  };
}

Object? _copyJsonValue(Object? value) {
  return switch (value) {
    Map<String, Object?> value => _copyJsonMap(value),
    Map value => _copyJsonMap(value.cast()),
    List value => value.map(_copyJsonValue).toList(),
    _ => value,
  };
}
