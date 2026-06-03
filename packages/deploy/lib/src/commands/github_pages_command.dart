import '../targets/github_pages.dart';
import 'base_command.dart';

/// `superdeck-deploy github-pages` — publish a built web app to GitHub Pages.
class GitHubPagesCommand extends DeployCommand {
  GitHubPagesCommand({super.loggerOverride, super.processRunner}) {
    argParser
      ..addOption(
        'branch',
        abbr: 'b',
        help: 'Branch to publish the built site into.',
        defaultsTo: 'gh-pages',
      )
      ..addOption(
        'message',
        abbr: 'm',
        help: 'Commit message for the publish commit.',
        defaultsTo: 'Publish SuperDeck app to GitHub Pages',
      )
      ..addFlag(
        'push',
        help: 'Push to origin after committing.',
        defaultsTo: true,
      )
      ..addFlag(
        'build',
        help: 'Run "flutter build web" before publishing.',
        defaultsTo: true,
      )
      ..addOption(
        'build-dir',
        help: 'Directory containing the built web assets.',
        defaultsTo: 'build/web',
      )
      ..addOption(
        'app-dir',
        help: 'Flutter app directory to build.',
        defaultsTo: '.',
      )
      ..addOption(
        'base-href',
        help: 'Override the auto-detected base href (e.g. "/my-repo/").',
      )
      ..addFlag(
        'dry-run',
        help: 'Plan the publish without making any changes.',
        negatable: false,
      );
  }

  @override
  Future<int> run() {
    final args = argResults!;
    final options = GitHubPagesOptions(
      branch: args['branch'] as String,
      message: args['message'] as String,
      push: args['push'] as bool,
      build: args['build'] as bool,
      buildDir: args['build-dir'] as String,
      appDir: args['app-dir'] as String,
      baseHref: args['base-href'] as String?,
      dryRun: args['dry-run'] as bool,
    );

    final target = GitHubPagesTarget(
      logger: logger,
      processRunner: processRunner,
    );

    return target.publish(options);
  }

  @override
  String get description => 'Publish a SuperDeck web app to GitHub Pages.';

  @override
  String get name => 'github-pages';
}
