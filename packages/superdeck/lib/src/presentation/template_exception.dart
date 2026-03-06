/// Exception thrown when template resolution fails.
class TemplateException implements Exception {
  final String message;

  const TemplateException(this.message);

  @override
  String toString() => 'TemplateException: $message';
}
