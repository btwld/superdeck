/// Generates a short, human-readable hash from a string value.
///
/// Produces an 8-character alphanumeric string that can be used for
/// generating unique identifiers (e.g., for slide keys, file names).
///
/// The hash is deterministic - the same input always produces the same output.
String generateValueHash(String valueToHash) {
  const characters =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  var hash = 0;

  for (var i = 0; i < valueToHash.length; i++) {
    final charCode = valueToHash.codeUnitAt(i);
    hash = (hash * 31 + charCode) % 2147483647;
  }

  var shortId = '';
  final base = characters.length;
  var remainingHash = hash;

  for (var i = 0; i < 8; i++) {
    shortId += characters[remainingHash % base];
    remainingHash = (remainingHash * 31 + hash + i) % 2147483647;
  }

  return shortId;
}
