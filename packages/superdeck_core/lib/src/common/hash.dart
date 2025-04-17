/// Generates a short, unique identifier from a given string.
/// This is needed as hashCode for strings is not guaranteed to be unique across different platforms
///
/// This function uses a hashing mechanism to transform the input string into
/// a unique, 8-character identifier. It is useful for creating compact and
/// unique keys for database entries, URLs, etc.
///
/// [valueToHash] is the string input that you want to convert into a hash ID.
///
/// Returns an 8-character string that represents the hashed ID.
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
