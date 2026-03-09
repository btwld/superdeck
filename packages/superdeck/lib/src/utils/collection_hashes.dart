int orderedIterableHash<T>(Iterable<T> values) {
  return Object.hashAll(values);
}

int unorderedMapHash<K, V>(Map<K, V> map) {
  return Object.hashAllUnordered(
    map.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}
