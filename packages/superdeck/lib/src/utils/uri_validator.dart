/// Validates and sanitizes URIs for safe image loading from markdown.
///
/// **Security Model**: This validator is designed for untrusted markdown content
/// where users provide image URLs. It prevents:
/// - Path traversal attacks (file:// with ..)
/// - Malformed URIs (crashes from Uri.parse)
/// - Unsupported schemes (e.g. `javascript:`)
///
/// **Intentionally Permissive**: Network URIs (http/https) allow localhost and
/// private IPs to support local development and corporate networks. This is
/// appropriate for a presentation tool where users control their own content.
///
/// **Not Used For**: YAML configuration files (ImageBlock) which are trusted.
///
/// Usage:
/// ```dart
/// try {
///   final uri = UriValidator.validate(src);
///   if (uri == null) return ErrorWidget('Image source is empty');
///   // use uri
/// } catch (e) {
///   return ErrorWidget(e.toString());
/// }
/// ```
class UriValidator {
  UriValidator._();

  /// Allowed URI schemes for images.
  ///
  /// `''` represents relative paths (e.g. `assets/logo.png`).
  static const allowedSchemes = {'', 'http', 'https', 'file'};

  /// Validates a URI string for safe image loading.
  ///
  /// Returns `null` if source is null/empty.
  /// Returns validated [Uri] if valid.
  /// Throws [FormatException] with descriptive message if invalid.
  static Uri? validate(String? src) {
    // Return null for empty sources
    if (src == null || src.trim().isEmpty) return null;

    // Parse URI safely
    final trimmed = src.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      throw FormatException('Invalid URI format: $trimmed');
    }

    // Reject protocol-relative URIs (e.g., //example.com)
    if (!uri.hasScheme && trimmed.startsWith('//')) {
      throw FormatException('Protocol-relative URIs are not supported');
    }

    // Validate scheme is in allowlist
    if (!allowedSchemes.contains(uri.scheme)) {
      throw FormatException(
        'Unsupported URI scheme: ${uri.scheme}. '
        'Allowed: ${allowedSchemes.join(", ")}',
      );
    }

    // Block path traversal attacks for non-network URIs
    // Network URIs (http/https) don't have path traversal risk in this context
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      if (trimmed.contains('..')) {
        throw FormatException('Path traversal detected');
      }
    }

    return uri;
  }
}
