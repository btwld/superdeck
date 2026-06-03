/// Deployment tooling for SuperDeck presentations.
///
/// Exposes the command runner and deploy targets so they can be driven
/// programmatically as well as through the `superdeck-deploy` executable.
library;

export 'src/commands/base_command.dart';
export 'src/commands/firebase_command.dart';
export 'src/commands/github_pages_command.dart';
export 'src/git/git_runner.dart';
export 'src/git/github_remote.dart';
export 'src/git/worktree.dart';
export 'src/runner.dart';
export 'src/targets/firebase.dart';
export 'src/targets/github_pages.dart';
export 'src/utils/branch_validation.dart';
export 'src/utils/constants.dart';
export 'src/utils/process_runner.dart';
export 'src/web/build_web.dart';
export 'src/web/index_html_template.dart';
