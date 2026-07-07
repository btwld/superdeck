Object? normalizeCatalogData(Object? value) {
  if (value is List) {
    return value.map(normalizeCatalogData).toList();
  }
  if (value is! Map) return value;

  return {
    for (final entry in value.entries)
      if (entry.key is String)
        entry.key as String: _normalizeCatalogEntry(
          entry.key as String,
          entry.value,
        ),
  };
}

Object? _normalizeCatalogEntry(String key, Object? value) {
  if (key == 'literalNumber' && value is int) {
    return value.toDouble();
  }

  return normalizeCatalogData(value);
}
