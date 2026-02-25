bool doesNotSetExplicitNullForOptionalKeys(
  Map<String, Object?> map,
  Iterable<String> keys,
) {
  for (final key in keys) {
    if (map.containsKey(key) && map[key] == null) {
      return false;
    }
  }

  return true;
}
