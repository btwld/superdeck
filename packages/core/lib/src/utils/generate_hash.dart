/// Generates a stable 8-character alphanumeric hash for identifiers like slide keys.
///
/// Uses a custom (non-cryptographic) algorithm that is consistent across platforms,
/// unlike Dart's built-in `hashCode`.
///
/// Internal utility — not part of the stable 1.0 API surface. May change
/// without a major version bump.
String generateValueHash(String valueToHash) {
  const characters =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  int hash = 0;

  for (int i = 0; i < valueToHash.length; i++) {
    int charCode = valueToHash.codeUnitAt(i);
    hash = (hash * 31 + charCode) % 2147483647;
  }

  String shortId = '';
  int base = characters.length;
  int remainingHash = hash;

  for (int i = 0; i < 8; i++) {
    shortId += characters[remainingHash % base];
    remainingHash = (remainingHash * 31 + hash + i) % 2147483647;
  }

  return shortId;
}
