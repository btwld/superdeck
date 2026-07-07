import 'dart:async';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../utils/ensure_pubspec_assets.dart';
import '../utils/extensions.dart';
import '../utils/logger.dart' show LoggerX;
import 'base_command.dart';

typedef RunDeckBuilderFactory =
    RunDeckBuilder Function(
      DeckWorkspace workspace,
      DeckBuildStore store,
      List<DeckBuildPlugin> plugins,
    );

typedef RunProcessLauncher =
    Future<Process> Function(
      String executable,
      List<String> arguments, {
      required String workingDirectory,
      required ProcessStartMode mode,
    });

typedef FlutterResolver =
    FutureOr<ResolvedFlutterCommand> Function(
      DeckWorkspace workspace,
      String? explicitFlutter,
    );

typedef ByteStreamConsumer = Future<void> Function(Stream<List<int>> stream);

abstract interface class RunDeckBuilder {
  Future<void> dispose();

  Stream<BuildEvent> watchAndBuild();

  Future<Iterable<Slide>> build();
}

abstract interface class RunCommandInput {
  Stream<List<int>> get byteStream;

  bool get echoMode;

  bool get hasTerminal;

  bool get lineMode;

  set echoMode(bool value);

  set lineMode(bool value);
}

final class ResolvedFlutterCommand {
  final String executable;
  final List<String> leadingArguments;

  const ResolvedFlutterCommand({
    required this.executable,
    this.leadingArguments = const [],
  });

  @override
  bool operator ==(Object other) {
    return other is ResolvedFlutterCommand &&
        other.executable == executable &&
        _stringListsEqual(other.leadingArguments, leadingArguments);
  }

  @override
  String toString() {
    return 'ResolvedFlutterCommand('
        'executable: $executable, '
        'leadingArguments: $leadingArguments'
        ')';
  }

  @override
  int get hashCode => Object.hash(executable, Object.hashAll(leadingArguments));
}

final class SystemRunCommandInput implements RunCommandInput {
  const SystemRunCommandInput();

  @override
  set echoMode(bool value) {
    stdin.echoMode = value;
  }

  @override
  set lineMode(bool value) {
    stdin.lineMode = value;
  }

  @override
  Stream<List<int>> get byteStream => stdin;

  @override
  bool get echoMode => stdin.echoMode;

  @override
  bool get hasTerminal => stdin.hasTerminal;

  @override
  bool get lineMode => stdin.lineMode;
}

/// Builds SuperDeck output and runs the Flutter app in one command.
class RunCommand extends SuperDeckCommand {
  final List<DeckBuildPlugin> plugins;
  final String? _projectDir;
  final RunDeckBuilderFactory _builderFactory;
  final RunProcessLauncher _processLauncher;
  final FlutterResolver _flutterResolver;
  final RunCommandInput _input;
  final ByteStreamConsumer _stdoutConsumer;
  final ByteStreamConsumer _stderrConsumer;
  final List<Stream<ProcessSignal>>? _signalStreams;
  final Duration _firstBuildTimeout;
  final Duration _signalGracePeriod;

  RunCommand({
    super.loggerOverride,
    String? projectDir,
    List<DeckBuildPlugin> plugins = const [],
    @visibleForTesting RunDeckBuilderFactory? builderFactory,
    @visibleForTesting RunProcessLauncher? processLauncher,
    @visibleForTesting FlutterResolver? flutterResolver,
    @visibleForTesting RunCommandInput? input,
    @visibleForTesting ByteStreamConsumer? stdoutConsumer,
    @visibleForTesting ByteStreamConsumer? stderrConsumer,
    @visibleForTesting List<Stream<ProcessSignal>>? signalStreams,
    @visibleForTesting Duration firstBuildTimeout = const Duration(seconds: 2),
    @visibleForTesting Duration signalGracePeriod = const Duration(seconds: 3),
  }) : plugins = List.unmodifiable(plugins),
       _projectDir = projectDir,
       _builderFactory = builderFactory ?? _createDeckBuilder,
       _processLauncher = processLauncher ?? _startProcess,
       _flutterResolver = flutterResolver ?? defaultFlutterResolver,
       _input = input ?? const SystemRunCommandInput(),
       _stdoutConsumer = stdoutConsumer ?? stdout.addStream,
       _stderrConsumer = stderrConsumer ?? stderr.addStream,
       _signalStreams = signalStreams,
       _firstBuildTimeout = firstBuildTimeout,
       _signalGracePeriod = signalGracePeriod {
    argParser
      ..addOption(
        'device-id',
        abbr: 'd',
        help: 'Forward a Flutter device id to `flutter run`.',
        valueHelp: 'id',
      )
      ..addOption(
        'flutter',
        help: 'Override the Flutter executable. Defaults to FVM when present.',
        valueHelp: 'path',
      )
      ..addFlag(
        'watch',
        help: 'Watch slides.md and rebuild while Flutter is running.',
        defaultsTo: true,
      )
      ..addFlag(
        'skip-pubspec',
        help: 'Skip updating pubspec assets',
        negatable: false,
      );
  }

  Future<bool> _buildOnce(
    RunDeckBuilder builder,
    DeckBuildStore store,
    DeckWorkspace workspace,
  ) async {
    final progress = logger.progress('Generating slides...');

    try {
      final slides = await builder.build();

      if (slides.isEmpty) {
        progress.update('No slides found.');
        logger.warn(
          'No slides found in ${workspace.slidesFile.path}. Make sure it '
          'exists and has proper content.',
        );
        progress.complete('Build completed with warnings.');

        return false;
      }

      progress.complete('Generated ${slides.length} slides.');

      return true;
    } on FileSystemException catch (error) {
      progress.fail('Build failed');
      logger.err('File system error: ${error.message}');
      logger.err('Path: ${error.path ?? 'Unknown'}');
      await store.saveBuildStatus(
        phase: .failure,
        error: error,
        stackTrace: .current,
      );

      return false;
    } on FormatException catch (error) {
      progress.fail('Format error');
      logger.err(error.message);
      await store.saveBuildStatus(
        phase: .failure,
        error: error,
        stackTrace: .current,
      );

      return false;
    } catch (error, stackTrace) {
      progress.fail('Build failed');
      _logBuildFailure(error, stackTrace);
      await store.saveBuildStatus(
        phase: .failure,
        error: error,
        stackTrace: stackTrace,
      );

      return false;
    }
  }

  Future<void> _waitForFirstWatchBuild(Completer<void> firstBuild) async {
    if (firstBuild.isCompleted) return;

    await Future.any<void>([
      firstBuild.future,
      Future<void>.delayed(_firstBuildTimeout),
    ]);
  }

  void _completeFirstBuild(Completer<void> firstBuild) {
    if (!firstBuild.isCompleted) {
      firstBuild.complete();
    }
  }

  void _logBuildEvent(BuildEvent event, Completer<void> firstBuild) {
    switch (event) {
      case BuildStarted():
        logger.info('File change detected. Rebuilding presentation...');
      case BuildCompleted(:final slides):
        if (slides.isEmpty) {
          logger.warn('No slides found in the deck.');
        } else {
          logger.success('Generated ${slides.length} slides.');
        }
        _completeFirstBuild(firstBuild);
      case BuildFailed(:final error, :final stackTrace):
        logger.err('Error processing slides during watch.');
        _logBuildFailure(error, stackTrace);
        _completeFirstBuild(firstBuild);
    }
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

  List<String> _flutterRunArguments(ResolvedFlutterCommand command) {
    final deviceId = argResults?['device-id'] as String?;

    return [
      ...command.leadingArguments,
      'run',
      if (deviceId != null && deviceId.isNotEmpty) ...['-d', deviceId],
      ...?argResults?.rest,
    ];
  }

  void _forwardSignal(Process process, ProcessSignal signal) {
    if (Platform.isWindows) {
      process.kill();
    } else {
      process.kill(signal);
    }
  }

  void _kill(Process process) {
    if (Platform.isWindows) {
      process.kill();
    } else {
      process.kill(.sigkill);
    }
  }

  Future<void> _saveRunFailure(
    DeckBuildStore? store,
    Object error,
    StackTrace stackTrace,
  ) async {
    await store?.saveBuildStatus(
      phase: .failure,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  Future<int> run() async {
    DeckBuildStore? store;
    RunDeckBuilder? builder;
    StreamSubscription<BuildEvent>? buildSubscription;
    final signalSubscriptions = <StreamSubscription<ProcessSignal>>[];
    final streamPassthroughs = <_StreamPassthrough>[];
    final stdinForwardings = <_StdinForwarding>[];
    Timer? signalGraceTimer;
    Process? process;
    final processExit = Completer<void>();
    var signalCount = 0;

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
        } catch (error) {
          logger.warn('Failed to update pubspec assets: $error');
        }
      }

      builder = _builderFactory(deckWorkspace, store, plugins);

      if (boolArg('watch')) {
        logger.info('');
        logger.info(
          'Run mode enabled. Building slides and launching Flutter from '
          '${deckWorkspace.projectDirectory.path}.',
        );
        logger.info(
          'Flutter owns hot reload keys (`r`, `R`, `q`, `h`); SuperDeck '
          'rebuilds slides from the file watcher.',
        );
        logger.info('');

        final firstBuild = Completer<void>();
        buildSubscription = builder.watchAndBuild().listen(
          (event) => _logBuildEvent(event, firstBuild),
          onError: (Object error, StackTrace stackTrace) {
            logger.err('Watch mode failed.');
            _logBuildFailure(error, stackTrace);
            _completeFirstBuild(firstBuild);
          },
        );
        await _waitForFirstWatchBuild(firstBuild);
      } else {
        final success = await _buildOnce(builder, store, deckWorkspace);
        if (!success) {
          return ExitCode.software.code;
        }
      }

      final flutterCommand = await _flutterResolver(
        deckWorkspace,
        argResults?['flutter'] as String?,
      );
      final flutterArguments = _flutterRunArguments(flutterCommand);
      process = await _processLauncher(
        flutterCommand.executable,
        flutterArguments,
        mode: .normal,
        workingDirectory: deckWorkspace.projectDirectory.path,
      );

      streamPassthroughs
        ..add(_StreamPassthrough.start(process.stdout, _stdoutConsumer))
        ..add(_StreamPassthrough.start(process.stderr, _stderrConsumer));
      final stdinForwarding = _StdinForwarding.start(_input, process.stdin);
      if (stdinForwarding != null) {
        stdinForwardings.add(stdinForwarding);
      }

      void requestShutdown(ProcessSignal signal) {
        if (processExit.isCompleted) return;
        signalCount++;
        if (signalCount == 1) {
          _forwardSignal(process!, signal);
          signalGraceTimer?.cancel();
          signalGraceTimer = Timer(_signalGracePeriod, () {
            if (!processExit.isCompleted) {
              _kill(process!);
            }
          });
        } else {
          signalGraceTimer?.cancel();
          _kill(process!);
        }
      }

      for (final signalStream in _signalStreams ?? _defaultSignalStreams()) {
        signalSubscriptions.add(signalStream.listen(requestShutdown));
      }

      final exitCode = await process.exitCode;
      if (!processExit.isCompleted) {
        processExit.complete();
      }

      return exitCode;
    } catch (error, stackTrace) {
      logger.err('Run failed before Flutter completed.');
      _logBuildFailure(error, stackTrace);
      await _saveRunFailure(store, error, stackTrace);

      return ExitCode.software.code;
    } finally {
      signalGraceTimer?.cancel();
      for (final subscription in signalSubscriptions) {
        await subscription.cancel();
      }
      for (final forwarding in stdinForwardings) {
        await forwarding.cancel();
      }
      if (process != null && !processExit.isCompleted) {
        _kill(process);
      }
      await buildSubscription?.cancel();
      await builder?.dispose();
      for (final passthrough in streamPassthroughs) {
        await passthrough.cancel();
      }
    }
  }

  @override
  String get description =>
      'Build and run a SuperDeck Flutter app from the current project';

  @override
  String get name => 'run';
}

ResolvedFlutterCommand resolveFlutterCommand({
  required String? explicitFlutter,
  required bool projectUsesFvm,
  required bool fvmOnPath,
}) {
  if (explicitFlutter != null && explicitFlutter.isNotEmpty) {
    return ResolvedFlutterCommand(executable: explicitFlutter);
  }

  if (projectUsesFvm && fvmOnPath) {
    return const ResolvedFlutterCommand(
      executable: 'fvm',
      leadingArguments: ['flutter'],
    );
  }

  return const ResolvedFlutterCommand(executable: 'flutter');
}

ResolvedFlutterCommand defaultFlutterResolver(
  DeckWorkspace workspace,
  String? explicitFlutter, {
  bool Function(String executable)? isExecutableOnPath,
}) {
  final projectDir = workspace.projectDirectory.path;
  final projectUsesFvm =
      File(p.join(projectDir, '.fvmrc')).existsSync() ||
      Directory(p.join(projectDir, '.fvm')).existsSync();
  final fvmOnPath = (isExecutableOnPath ?? _isExecutableOnPath)('fvm');

  return resolveFlutterCommand(
    explicitFlutter: explicitFlutter,
    projectUsesFvm: projectUsesFvm,
    fvmOnPath: fvmOnPath,
  );
}

bool _stringListsEqual(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }

  return true;
}

RunDeckBuilder _createDeckBuilder(
  DeckWorkspace workspace,
  DeckBuildStore store,
  List<DeckBuildPlugin> plugins,
) {
  return _DeckBuilderAdapter(
    DeckBuilder(workspace: workspace, store: store, plugins: plugins),
  );
}

Future<Process> _startProcess(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
  required ProcessStartMode mode,
}) {
  return Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    mode: mode,
  );
}

List<Stream<ProcessSignal>> _defaultSignalStreams() {
  return [
    ProcessSignal.sigint.watch(),
    if (!Platform.isWindows) ProcessSignal.sigterm.watch(),
  ];
}

bool _isExecutableOnPath(String executable) {
  if (p.isAbsolute(executable)) {
    return File(executable).existsSync();
  }

  final pathEnv = Platform.environment['PATH'];
  if (pathEnv == null || pathEnv.isEmpty) return false;

  final separator = Platform.isWindows ? ';' : ':';
  final extensions = Platform.isWindows
      ? (Platform.environment['PATHEXT'] ?? '.EXE;.BAT;.CMD')
            .split(';')
            .where((extension) => extension.isNotEmpty)
            .toList(growable: false)
      : const [''];

  for (final directory in pathEnv.split(separator)) {
    for (final extension in extensions) {
      if (File(p.join(directory, '$executable$extension')).existsSync()) {
        return true;
      }
    }
  }

  return false;
}

final class _DeckBuilderAdapter implements RunDeckBuilder {
  final DeckBuilder _delegate;

  const _DeckBuilderAdapter(this._delegate);

  @override
  Future<void> dispose() => _delegate.dispose();

  @override
  Stream<BuildEvent> watchAndBuild() => _delegate.watchAndBuild();

  @override
  Future<Iterable<Slide>> build() => _delegate.build();
}

final class _StreamPassthrough {
  final StreamController<List<int>> _controller;
  final StreamSubscription<List<int>> _subscription;
  final Future<void> _consumerTask;

  const _StreamPassthrough._(
    this._controller,
    this._subscription,
    this._consumerTask,
  );

  static _StreamPassthrough start(
    Stream<List<int>> source,
    ByteStreamConsumer consumer,
  ) {
    final controller = StreamController<List<int>>.broadcast();
    final consumerTask = consumer(controller.stream);
    final subscription = source.listen(
      controller.add,
      onError: controller.addError,
      onDone: () {
        unawaited(controller.close());
      },
    );

    return _StreamPassthrough._(controller, subscription, consumerTask);
  }

  Future<void> cancel() async {
    await _subscription.cancel();
    if (!_controller.isClosed) {
      await _controller.close();
    }
    await _consumerTask;
  }
}

final class _StdinForwarding {
  final RunCommandInput _input;
  final bool _previousLineMode;
  final bool _previousEchoMode;
  final StreamSubscription<List<int>> _subscription;

  const _StdinForwarding._(
    this._input,
    this._previousLineMode,
    this._previousEchoMode,
    this._subscription,
  );

  static _StdinForwarding? start(RunCommandInput input, IOSink childStdin) {
    if (!input.hasTerminal) return null;

    final previousLineMode = input.lineMode;
    final previousEchoMode = input.echoMode;
    input.lineMode = false;
    input.echoMode = false;

    final subscription = input.byteStream.listen((bytes) {
      try {
        childStdin.add(bytes);
      } catch (_) {
        // The child may close stdin while the terminal stream is still open.
      }
    }, onError: childStdin.addError);

    return _StdinForwarding._(
      input,
      previousLineMode,
      previousEchoMode,
      subscription,
    );
  }

  Future<void> cancel() async {
    await _subscription.cancel();
    _input.echoMode = _previousEchoMode;
    _input.lineMode = _previousLineMode;
  }
}
