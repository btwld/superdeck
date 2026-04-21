import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../utils/extensions.dart';
import '../utils/logger.dart' show LoggerX;
import '../utils/update_pubspec.dart';
import 'base_command.dart';

/// Builds SuperDeck presentations from markdown.
///
/// Parses the slides.md file and writes the compiled deck to the workspace
/// output directory.
class BuildCommand extends SuperDeckCommand {
  bool _isRunning = false;
  final String? _projectDir;

  BuildCommand({super.loggerOverride, String? projectDir})
    : _projectDir = projectDir {
    argParser
      ..addFlag(
        'watch',
        abbr: 'w',
        help: 'Watch for changes and build the deck',
        negatable: false,
      )
      ..addFlag(
        'skip-pubspec',
        help: 'Skip updating pubspec assets',
        negatable: false,
      );
  }

  void _logBuildFailure(Object error, [StackTrace? stackTrace]) {
    if (error is DeckFormatException) {
      logger.formatError(error);
    } else {
      logger.err('${error.runtimeType}: $error');
    }

    if (stackTrace != null) {
      final trace = stackTrace.toString().trim();
      if (trace.isNotEmpty) {
        logger.err('Stack trace:');
        logger.err(trace);
      }
    }
  }

  /// Runs the build process with proper error handling and progress reporting.
  ///
  /// Uses the provided [builder] for the build, or creates a new one if not
  /// provided.
  Future<bool> _runBuild(
    DeckBuildStore store,
    DeckWorkspace workspace, {
    DeckBuilder? builder,
  }) async {
    while (_isRunning) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _isRunning = true;
    final progress = logger.progress('Generating slides...');

    builder ??= DeckBuilder(workspace: workspace, store: store);

    try {
      final slides = await builder.build();

      if (slides.isEmpty) {
        progress.update('No slides found.');
        logger.warn(
          'No slides found in ${workspace.slidesFile.path}. Make sure it exists '
          'and has proper content.',
        );
        progress.complete('Build completed with warnings.');

        return false;
      }

      progress.complete('Generated ${slides.length} slides.');

      return true;
    } on FileSystemException catch (e) {
      progress.fail('Build failed');
      logger.err('File system error: ${e.message}');
      logger.err('Path: ${e.path ?? 'Unknown'}');
      await store.saveBuildStatus(
        phase: DeckBuildPhase.failure,
        error: e,
        stackTrace: StackTrace.current,
      );

      return false;
    } on FormatException catch (e) {
      progress.fail('Format error');
      logger.err(e.message);
      await store.saveBuildStatus(
        phase: DeckBuildPhase.failure,
        error: e,
        stackTrace: StackTrace.current,
      );

      return false;
    } catch (e, stackTrace) {
      progress.fail('Build failed');
      _logBuildFailure(e, stackTrace);
      await store.saveBuildStatus(
        phase: DeckBuildPhase.failure,
        error: e,
        stackTrace: stackTrace,
      );

      return false;
    } finally {
      _isRunning = false;
    }
  }

  @override
  Future<int> run() async {
    DeckBuildStore? store;
    try {
      final deckWorkspace = DeckWorkspace(projectDir: _projectDir);

      if (!await deckWorkspace.slidesFile.exists()) {
        logger.err('Slides file not found: ${deckWorkspace.slidesFile.path}');
        logger.info(
          'Add a slides.md file in the project root. If this app has not been '
          'configured for SuperDeck yet, run `superdeck setup` first to add '
          'the required pubspec entries, web loader, and macOS entitlements.',
        );

        return ExitCode.unavailable.code;
      }

      store = DeckBuildStore(workspace: deckWorkspace);
      await store.initialize();

      if (!boolArg('skip-pubspec')) {
        try {
          await _ensurePubspecAssets(deckWorkspace, logger);
        } catch (e) {
          logger.warn('Failed to update pubspec assets: $e');
        }
      }

      if (!boolArg('watch')) {
        final success = await _runBuild(store, deckWorkspace);

        if (!success) {
          return ExitCode.software.code;
        }
      }

      // Watch mode
      if (boolArg('watch')) {
        logger.info('');
        logger.info(
          'Watch mode enabled. Listening for changes in slides file.',
        );
        logger.info('');
        logger.info('Commands:');
        logger.info('  r - Rebuild presentation');
        logger.info('  q - Quit watch mode');
        logger.info('');
        logger.info('Press Ctrl+C to stop watching.');
        logger.info('');

        // Create a builder that will handle watching and rebuilding
        final builder = DeckBuilder(workspace: deckWorkspace, store: store);

        // Listen to stdin for interactive commands
        StreamSubscription<String>? stdinSubscription;
        try {
          stdinSubscription = stdin
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .listen((line) async {
                final command = line.trim().toLowerCase();
                switch (command) {
                  case 'r':
                  case 'rebuild':
                    logger.info('Manual rebuild triggered...');
                    unawaited(
                      _runBuild(store!, deckWorkspace, builder: builder),
                    );
                    break;
                  case 'q':
                  case 'quit':
                    logger.info('Exiting watch mode...');
                    await stdinSubscription?.cancel();
                    exit(ExitCode.success.code);
                  default:
                    logger.warn('Unknown command: "$command"');
                    logger.info(
                      'Available commands: r (rebuild), q (quit)',
                    );
                }
              });

          await for (final event in builder.watchAndBuild()) {
            switch (event) {
              case BuildStarted():
                logger.info('File change detected. Rebuilding presentation...');
              case BuildCompleted(:final slides):
                if (slides.isEmpty) {
                  logger.warn('No slides found in the deck.');
                } else {
                  logger.success('Generated ${slides.length} slides.');
                }
              case BuildFailed(:final error, :final stackTrace):
                logger.err('Error processing slides during watch.');
                _logBuildFailure(error, stackTrace);
            }
          }
        } finally {
          await stdinSubscription?.cancel();
        }
      }

      return ExitCode.success.code;
    } catch (e, stackTrace) {
      logger.err('Build failed before the deck could be generated.');
      _logBuildFailure(e, stackTrace);
      await store?.saveBuildStatus(
        phase: DeckBuildPhase.failure,
        error: e,
        stackTrace: stackTrace,
      );

      return ExitCode.software.code;
    }
  }

  @override
  String get description => 'Build SuperDeck presentations from markdown';

  @override
  String get name => 'build';
}

/// Ensures the pubspec.yaml has the necessary assets configuration.
Future<void> _ensurePubspecAssets(
  DeckWorkspace workspace,
  Logger logger,
) async {
  final progress = logger.progress('Checking pubspec.yaml assets...');

  final pubspecFile = workspace.pubspecFile;

  if (!await pubspecFile.exists()) {
    progress.fail('pubspec.yaml not found');

    return;
  }

  final pubspecContents = await pubspecFile.readAsString();
  final updatedPubspecContents = updatePubspecAssets(
    workspace,
    pubspecContents,
  );

  if (updatedPubspecContents != pubspecContents) {
    await pubspecFile.writeAsString(updatedPubspecContents);
    progress.complete('Pubspec assets updated');
  } else {
    progress.complete('Pubspec assets already configured');
  }
}
