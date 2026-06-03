/// Deployment tooling for SuperDeck presentations.
///
/// Exposes the command runner and deploy targets so they can be driven
/// programmatically as well as through the `superdeck-deploy` executable.
library;

export 'src/runner.dart' show DeployRunner;
export 'src/targets/github_pages.dart'
    show GitHubPagesOptions, GitHubPagesTarget;
export 'src/utils/process_runner.dart' show ProcessRunner, defaultProcessRunner;
