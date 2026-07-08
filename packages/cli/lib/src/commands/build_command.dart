import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';
import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../utils/ensure_pubspec_assets.dart';
import '../utils/extensions.dart';
import '../utils/logger.dart' show LoggerX;
import 'base_command.dart';

/// Builds SuperDeck presentations from markdown.
///
/// Parses the slides.md file and writes the compiled deck to the workspace
/// output directory.
class BuildCommand extends SuperDeckCommand {
  final List<DeckBuildPlugin> plugins;
  bool _isRunning = false;
  final String? _projectDir;
  final Stream<String>? _commandInput;
  final bool? _stdinIsInteractive;
  final Future<void>? _watchQuitSignal;
  final void Function()? _watchReady;

  BuildCommand({
    super.loggerOverride,
    String? projectDir,
    List<DeckBuildPlugin> plugins = const [],
    @visibleForTesting Stream<String>? commandInput,
    @visibleForTesting bool? stdinIsInteractive,
    @visibleForTesting Future<void>? watchQuitSignal,
    @visibleForTesting void Function()? watchReady,
  }) : plugins = List.unmodifiable(plugins),
       _projectDir = projectDir,
       _commandInput = commandInput,
       _stdinIsInteractive = stdinIsInteractive,
       _watchQuitSignal = watchQuitSignal,
       _watchReady = watchReady {
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

    final ownsBuilder = builder == null;
    builder ??= DeckBuilder(
      workspace: workspace,
      store: store,
      plugins: plugins,
    );

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
        phase: .failure,
        error: e,
        stackTrace: .current,
      );

      return false;
    } on FormatException catch (e) {
      progress.fail('Format error');
      logger.err(e.message);
      await store.saveBuildStatus(
        phase: .failure,
        error: e,
        stackTrace: .current,
      );

      return false;
    } catch (e, stackTrace) {
      progress.fail('Build failed');
      _logBuildFailure(e, stackTrace);
      await store.saveBuildStatus(
        phase: .failure,
        error: e,
        stackTrace: stackTrace,
      );

      return false;
    } finally {
      if (ownsBuilder) {
        await builder.dispose();
      }
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
          'the required pubspec entries and macOS entitlements.',
        );

        return ExitCode.unavailable.code;
      }

      store = DeckBuildStore(workspace: deckWorkspace);
      await store.initialize();

      if (!boolArg('skip-pubspec')) {
        try {
          await ensurePubspecAssets(deckWorkspace, logger);
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
        final builder = DeckBuilder(
          workspace: deckWorkspace,
          store: store,
          plugins: plugins,
        );

        // Listen to stdin for interactive commands
        final quitRequested = Completer<void>();
        var watchExitCode = ExitCode.success.code;

        void requestQuit([int exitCode = 0]) {
          if (quitRequested.isCompleted) return;
          watchExitCode = exitCode;
          quitRequested.complete();
        }

        final interactive = _stdinIsInteractive ?? stdin.hasTerminal;
        final lines =
            _commandInput ??
            stdin.transform(utf8.decoder).transform(const LineSplitter());
        final stdinSubscription = lines.listen(
          (line) {
            final command = line.trim().toLowerCase();
            switch (command) {
              case 'r':
              case 'rebuild':
                logger.info('Manual rebuild triggered...');
                unawaited(_runBuild(store!, deckWorkspace, builder: builder));
                break;
              case 'q':
              case 'quit':
                logger.info('Exiting watch mode...');
                requestQuit(ExitCode.success.code);
                break;
              default:
                logger.warn('Unknown command: "$command"');
                logger.info('Available commands: r (rebuild), q (quit)');
            }
          },
          onDone: () {
            if (interactive) requestQuit();
          },
        );
        final watchQuitSubscription = _watchQuitSignal?.asStream().listen(
          (_) => requestQuit(ExitCode.success.code),
        );

        final buildSubscription = builder.watchAndBuild().listen(
          (event) {
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
          },
          onError: (Object error, StackTrace stackTrace) {
            logger.err('Watch mode failed.');
            _logBuildFailure(error, stackTrace);
            requestQuit(ExitCode.software.code);
          },
        );
        _watchReady?.call();

        try {
          await quitRequested.future;

          return watchExitCode;
        } finally {
          await stdinSubscription.cancel();
          await watchQuitSubscription?.cancel();
          await buildSubscription.cancel();
          await builder.dispose();
        }
      }

      return ExitCode.success.code;
    } catch (e, stackTrace) {
      logger.err('Build failed before the deck could be generated.');
      _logBuildFailure(e, stackTrace);
      await store?.saveBuildStatus(
        phase: .failure,
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
