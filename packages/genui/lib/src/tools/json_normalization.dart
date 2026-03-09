Map<String, Object?> stripNullsFromJsonMap(Map<String, Object?> input) {
  final normalized = <String, Object?>{};

  for (final entry in input.entries) {
    final value = _stripNulls(entry.value);
    if (value != null) {
      normalized[entry.key] = value;
    }
  }

  return normalized;
}

Object? _stripNulls(Object? value) {
  if (value is Map) {
    return stripNullsFromJsonMap(Map<String, Object?>.from(value));
  }

  if (value is List) {
    final normalized = value
        .map(_stripNulls)
        .where((entry) => entry != null)
        .cast<Object?>()
        .toList();
    return normalized;
  }

  return value;
}
