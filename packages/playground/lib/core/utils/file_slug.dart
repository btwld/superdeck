final _nonSlugCharacters = RegExp(r'[^a-z0-9]+');
final _edgeDashes = RegExp(r'^-+|-+$');
final _trailingDashes = RegExp(r'-+$');

/// Converts user-facing text into a bounded, lowercase filename component.
String toFileSlug(
  String value, {
  required String fallback,
  int maxLength = 64,
}) {
  final slug = value
      .trim()
      .toLowerCase()
      .replaceAll(_nonSlugCharacters, '-')
      .replaceAll(_edgeDashes, '');
  final safeSlug = slug.isEmpty ? fallback : slug;
  if (safeSlug.length <= maxLength) return safeSlug;
  return safeSlug.substring(0, maxLength).replaceFirst(_trailingDashes, '');
}
