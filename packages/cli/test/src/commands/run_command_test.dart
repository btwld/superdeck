import 'dart:async';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_cli/src/commands/run_command.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('RunCommand', () {
    late Directory tempDir;
    late DeckWorkspace workspace;

    setUp(() async {
      tempDir = await createTempDirAsync();
      workspace = DeckWorkspace(projectDir: tempDir.path);
      await workspace.slidesFile.writeAsString('# Test\n\nContent');
      createTestPubspec(tempDir);
    });

    test('has the expected command metadata and flags', () {
      final command = RunCommand();

      expect(command.name, 'run');
      expect(command.description, contains('Build and run'));
      expect(command.argParser.options, contains('device-id'));
      expect(command.argParser.options['device-id']!.abbr, 'd');
      expect(command.argParser.options, contains('flutter'));
      expect(command.argParser.options, contains('skip-pubspec'));
      expect(command.argParser.options['skip-pubspec']!.negatable, isFalse);
      expect(command.argParser.options, contains('watch'));
      expect(command.argParser.options['watch']!.defaultsTo, isTrue);
      expect(command.argParser.options['watch']!.negatable, isTrue);
    });

    test('forwards device id, rest args, and flutter exit code', () async {
      final builder = _FakeRunDeckBuilder()..buildSlides = [_slide()];
      final process = _FakeProcess(exitCode: 23)..completeOnListen();
      final launcher = _RecordingLauncher(process);
      final input = _FakeRunCommandInput(hasTerminal: false);
      final command = RunCommand(
        projectDir: tempDir.path,
        builderFactory: (_, _, _) => builder,
        processLauncher: launcher.call,
        flutterResolver: (_, _) async =>
            const ResolvedFlutterCommand(executable: '/custom/flutter'),
        input: input,
        stdoutConsumer: (_) async {},
        stderrConsumer: (_) async {},
      );

      final runner = createTestRunner(command);
      final result = await runner.run([
        'run',
        '-d',
        'macos',
        '--no-watch',
        '--skip-pubspec',
        '--',
        '--dart-define=FOO=bar',
      ]);

      expect(result, 23);
      expect(builder.buildCount, 1);
      expect(builder.watchCount, 0);
      expect(builder.disposed, isTrue);
      expect(launcher.executable, '/custom/flutter');
      expect(launcher.arguments, [
        'run',
        '-d',
        'macos',
        '--dart-define=FOO=bar',
      ]);
      expect(input.listened, isFalse);
      expect(input.lineModeSetCount, 0);
      expect(input.echoModeSetCount, 0);
    });

    test('starts the watcher before launching flutter', () async {
      final events = <String>[];
      final builder = _FakeRunDeckBuilder(
        onWatchListen: () => events.add('watch'),
        onWatchCancel: () => events.add('cancel-watch'),
      )..watchEvents = _openWatchEvents([_slide()]);
      final process = _FakeProcess(exitCode: ExitCode.success.code)
        ..completeOnListen();
      final launcher = _RecordingLauncher(
        process,
        onLaunch: () => events.add('flutter'),
      );
      final command = RunCommand(
        projectDir: tempDir.path,
        builderFactory: (_, _, _) => builder,
        processLauncher: launcher.call,
        flutterResolver: (_, _) async =>
            const ResolvedFlutterCommand(executable: 'flutter'),
        input: _FakeRunCommandInput(hasTerminal: false),
        stdoutConsumer: (_) async {},
        stderrConsumer: (_) async {},
      );

      final runner = createTestRunner(command);
      final result = await runner.run(['run', '--skip-pubspec']);

      expect(result, ExitCode.success.code);
      expect(events, ['watch', 'flutter', 'cancel-watch']);
      expect(builder.disposed, isTrue);
    });

    test('forwards SIGINT to flutter and propagates its exit code', () async {
      final signalListening = Completer<void>();
      final signalController = StreamController<ProcessSignal>.broadcast(
        onListen: () {
          if (!signalListening.isCompleted) signalListening.complete();
        },
      );
      final builder = _FakeRunDeckBuilder()..buildSlides = [_slide()];
      final process = _FakeProcess(exitCode: 130, completeWhenKilled: true);
      final launcher = _RecordingLauncher(process);
      final command = RunCommand(
        projectDir: tempDir.path,
        builderFactory: (_, _, _) => builder,
        processLauncher: launcher.call,
        signalStreams: [signalController.stream],
        flutterResolver: (_, _) async =>
            const ResolvedFlutterCommand(executable: 'flutter'),
        input: _FakeRunCommandInput(hasTerminal: false),
        stdoutConsumer: (_) async {},
        stderrConsumer: (_) async {},
      );

      final runner = createTestRunner(command);
      final runFuture = runner.run(['run', '--no-watch', '--skip-pubspec']);

      await launcher.started.future;
      await signalListening.future;
      signalController.add(ProcessSignal.sigint);

      expect(await runFuture, 130);
      expect(process.signals, [ProcessSignal.sigint]);
      expect(builder.disposed, isTrue);

      await signalController.close();
    });

    test('escalates a second signal immediately', () async {
      final signalListening = Completer<void>();
      final signalController = StreamController<ProcessSignal>.broadcast(
        onListen: () {
          if (!signalListening.isCompleted) signalListening.complete();
        },
      );
      final builder = _FakeRunDeckBuilder()..buildSlides = [_slide()];
      final process = _FakeProcess(exitCode: 130);
      final launcher = _RecordingLauncher(process);
      final command = RunCommand(
        projectDir: tempDir.path,
        builderFactory: (_, _, _) => builder,
        processLauncher: launcher.call,
        signalStreams: [signalController.stream],
        flutterResolver: (_, _) async =>
            const ResolvedFlutterCommand(executable: 'flutter'),
        input: _FakeRunCommandInput(hasTerminal: false),
        stdoutConsumer: (_) async {},
        stderrConsumer: (_) async {},
        signalGracePeriod: const Duration(seconds: 30),
      );

      final runner = createTestRunner(command);
      final runFuture = runner.run(['run', '--no-watch', '--skip-pubspec']);

      await launcher.started.future;
      await signalListening.future;
      signalController
        ..add(ProcessSignal.sigint)
        ..add(ProcessSignal.sigint);
      await Future<void>.delayed(Duration.zero);
      process.complete();

      expect(await runFuture, 130);
      expect(process.signals, [ProcessSignal.sigint, ProcessSignal.sigkill]);

      await signalController.close();
    });

    test('resolves flutter command choices', () {
      expect(
        resolveFlutterCommand(
          explicitFlutter: '/opt/flutter/bin/flutter',
          projectUsesFvm: true,
          fvmOnPath: true,
        ),
        const ResolvedFlutterCommand(executable: '/opt/flutter/bin/flutter'),
      );
      expect(
        resolveFlutterCommand(
          explicitFlutter: null,
          projectUsesFvm: true,
          fvmOnPath: true,
        ),
        const ResolvedFlutterCommand(
          executable: 'fvm',
          leadingArguments: ['flutter'],
        ),
      );
      expect(
        resolveFlutterCommand(
          explicitFlutter: null,
          projectUsesFvm: true,
          fvmOnPath: false,
        ),
        const ResolvedFlutterCommand(executable: 'flutter'),
      );
      expect(
        resolveFlutterCommand(
          explicitFlutter: null,
          projectUsesFvm: false,
          fvmOnPath: true,
        ),
        const ResolvedFlutterCommand(executable: 'flutter'),
      );
    });

    test('detects project FVM config when resolving default flutter', () async {
      final fvmrc = File('${tempDir.path}/.fvmrc');
      await fvmrc.writeAsString('3.44.0');

      final command = defaultFlutterResolver(
        workspace,
        null,
        isExecutableOnPath: (name) => name == 'fvm',
      );

      expect(
        command,
        const ResolvedFlutterCommand(
          executable: 'fvm',
          leadingArguments: ['flutter'],
        ),
      );
    });
  });
}

Slide _slide() {
  return Slide(
    key: 'slide',
    sections: [
      SectionBlock([ContentBlock('Content')]),
    ],
  );
}

Stream<BuildEvent> _openWatchEvents(List<Slide> slides) async* {
  yield const BuildStarted();
  yield BuildCompleted(slides);
  await Completer<void>().future;
}

final class _FakeRunDeckBuilder implements RunDeckBuilder {
  _FakeRunDeckBuilder({this.onWatchListen, this.onWatchCancel});

  final void Function()? onWatchListen;
  final void Function()? onWatchCancel;
  Iterable<Slide> buildSlides = const [];
  Stream<BuildEvent> watchEvents = const Stream<BuildEvent>.empty();
  int buildCount = 0;
  int watchCount = 0;
  bool disposed = false;

  @override
  Future<Iterable<Slide>> build() async {
    buildCount++;
    return buildSlides;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  @override
  Stream<BuildEvent> watchAndBuild() {
    watchCount++;
    return watchEvents
        .transform(
          StreamTransformer<BuildEvent, BuildEvent>.fromHandlers(
            handleData: (event, sink) => sink.add(event),
            handleDone: (sink) => sink.close(),
          ),
        )
        .asBroadcastStream(
          onListen: (_) => onWatchListen?.call(),
          onCancel: (_) => onWatchCancel?.call(),
        );
  }
}

final class _RecordingLauncher {
  _RecordingLauncher(this.process, {this.onLaunch});

  final _FakeProcess process;
  final void Function()? onLaunch;
  final started = Completer<void>();
  String? executable;
  List<String>? arguments;

  Future<Process> call(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
    required ProcessStartMode mode,
  }) async {
    this.executable = executable;
    this.arguments = arguments;
    onLaunch?.call();
    if (!started.isCompleted) started.complete();
    return process;
  }
}

final class _FakeRunCommandInput implements RunCommandInput {
  _FakeRunCommandInput({required this.hasTerminal});

  @override
  final bool hasTerminal;

  int lineModeSetCount = 0;
  int echoModeSetCount = 0;
  bool listened = false;

  @override
  set lineMode(bool value) {
    lineModeSetCount++;
    _lineMode = value;
  }

  @override
  bool get lineMode => _lineMode;
  bool _lineMode = true;

  @override
  set echoMode(bool value) {
    echoModeSetCount++;
    _echoMode = value;
  }

  @override
  bool get echoMode => _echoMode;
  bool _echoMode = true;

  @override
  Stream<List<int>> get byteStream {
    return StreamController<List<int>>(onListen: () => listened = true).stream;
  }
}

final class _FakeProcess implements Process {
  _FakeProcess({required int exitCode, this.completeWhenKilled = false})
    : _stdinController = StreamController<List<int>>(),
      _stdoutController = StreamController<List<int>>(),
      _stderrController = StreamController<List<int>>(),
      _exitCodeValue = exitCode;

  final int _exitCodeValue;
  final bool completeWhenKilled;
  final StreamController<List<int>> _stdinController;
  final StreamController<List<int>> _stdoutController;
  final StreamController<List<int>> _stderrController;
  final _exitCompleter = Completer<int>();
  final List<ProcessSignal> signals = [];

  late final IOSink _stdin = IOSink(_stdinController.sink);

  @override
  Future<int> get exitCode => _exitCompleter.future;

  @override
  int get pid => 42;

  @override
  IOSink get stdin => _stdin;

  @override
  Stream<List<int>> get stderr => _stderrController.stream;

  @override
  Stream<List<int>> get stdout => _stdoutController.stream;

  void completeOnListen() {
    scheduleMicrotask(complete);
  }

  void complete() {
    if (_exitCompleter.isCompleted) return;
    _exitCompleter.complete(_exitCodeValue);
    unawaited(_stdoutController.close());
    unawaited(_stderrController.close());
    unawaited(_stdin.close());
  }

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    signals.add(signal);
    if (completeWhenKilled) {
      complete();
    }
    return true;
  }
}
