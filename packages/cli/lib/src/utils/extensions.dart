import 'package:args/command_runner.dart';

extension CommandX on Command {
  bool boolArg(String name) => argResults?[name] == true;
}
