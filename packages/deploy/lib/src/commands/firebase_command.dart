import '../targets/firebase.dart';
import 'base_command.dart';

/// `superdeck-deploy firebase` — deploy a built web app to Firebase Hosting.
class FirebaseCommand extends DeployCommand {
  FirebaseCommand({super.loggerOverride, super.processRunner}) {
    argParser
      ..addOption(
        'app-dir',
        help: 'Directory containing firebase.json (the hosting root).',
        defaultsTo: '.',
      )
      ..addOption('project', help: 'Firebase project id (--project).')
      ..addOption(
        'channel',
        help: 'Deploy to a preview channel instead of live.',
      )
      ..addFlag(
        'dry-run',
        help: 'Plan the deploy without running Firebase.',
        negatable: false,
      );
  }

  @override
  Future<int> run() {
    final args = argResults!;
    final options = FirebaseOptions(
      appDir: args['app-dir'] as String,
      project: args['project'] as String?,
      channel: args['channel'] as String?,
      dryRun: args['dry-run'] as bool,
    );

    final target = FirebaseTarget(
      logger: logger,
      processRunner: processRunner,
    );

    return target.deploy(options);
  }

  @override
  String get description =>
      'Deploy a SuperDeck web app to Firebase Hosting.';

  @override
  String get name => 'firebase';
}
