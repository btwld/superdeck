Map<String, dynamic> deepMerge(
    Map<String, dynamic> map1, Map<String, dynamic> map2) {
  Map<String, dynamic> result = {};

  void merge(Map<String, dynamic> target, Map<String, dynamic> source) {
    source.forEach((key, value) {
      if (target.containsKey(key)) {
        if (target[key] is Map<String, dynamic> &&
            value is Map<String, dynamic>) {
          merge(target[key], value);
        } else {
          target[key] = value;
        }
      } else {
        target[key] = value;
      }
    });
  }

  merge(result, map1);
  merge(result, map2);

  return result;
}
