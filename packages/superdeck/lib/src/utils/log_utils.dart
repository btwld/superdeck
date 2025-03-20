/// ANSI color codes for terminal output
class _AnsiColor {
  final String code;

  const _AnsiColor(this.code);

  static const reset = _AnsiColor('\x1B[0m');
  static const red = _AnsiColor('\x1B[31m');
  static const green = _AnsiColor('\x1B[32m');
  static const yellow = _AnsiColor('\x1B[33m');
  static const cyan = _AnsiColor('\x1B[36m');
}
