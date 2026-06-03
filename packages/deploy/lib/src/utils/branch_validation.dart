/// Valid git branch name pattern: must start alphanumeric and contain only
/// letters, numbers, dots, hyphens, underscores, or slashes.
final _validBranchNamePattern = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._/-]*$');

final _controlCharacterPattern = RegExp(r'[\s\x00-\x1f\x7f]');

/// Validates a git branch name to prevent command injection and malformed
/// refs.
///
/// Rejects empty names, path traversal (`..`), names that could be parsed as
/// flags (leading `-`), and names containing whitespace or control characters.
bool isValidBranchName(String branch) {
  if (branch.isEmpty) return false;
  if (branch.contains('..')) return false;
  if (branch.startsWith('-')) return false;
  if (branch.contains(_controlCharacterPattern)) return false;

  return _validBranchNamePattern.hasMatch(branch);
}
