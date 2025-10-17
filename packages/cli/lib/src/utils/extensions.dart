import 'package:args/command_runner.dart';

extension CommandExtension on Command {
  /// Gets the parsed command-line option named [name] as `bool`.
  bool boolArg(String name) => argResults?[name] == true;
}
