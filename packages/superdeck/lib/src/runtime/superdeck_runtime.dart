import 'package:flutter/foundation.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../presentation/deck_extension.dart';
import '../presentation/deck_theme.dart';
import '../utils/app_initialization.dart';
import 'deck_config.dart';
import 'superdeck_handle.dart';

final class SuperDeckRuntime {
  final DeckConfig config;
  final DeckTheme theme;
  final List<DeckExtension> extensions;
  final SuperDeckHandle handle;

  final DeckWorkspace _workspace;

  SuperDeckRuntime._({
    required this.config,
    required this.theme,
    required this.extensions,
    required this.handle,
    required DeckWorkspace workspace,
  }) : _workspace = workspace;

  static Future<SuperDeckRuntime> create({
    required DeckConfig config,
    DeckTheme theme = const DeckTheme(),
    List<DeckExtension> extensions = const <DeckExtension>[],
  }) async {
    if (kIsWeb && config is LocalDeckConfig) {
      throw UnsupportedError(
        'DeckConfig.local is not supported on web runtimes. '
        'Use DeckConfig.bundle(...) instead.',
      );
    }

    await initializeDependencies();
    for (final extension in extensions) {
      try {
        await extension.initialize();
      } catch (error, stackTrace) {
        debugPrint(
          'DeckExtension "${extension.name}" failed to initialize: '
          '$error\n$stackTrace',
        );
      }
    }

    return _buildRuntime(config: config, theme: theme, extensions: extensions);
  }

  @visibleForTesting
  static SuperDeckRuntime forTesting({
    DeckConfig config = const DeckConfig.bundle(),
    DeckTheme theme = const DeckTheme(),
    List<DeckExtension> extensions = const <DeckExtension>[],
    SuperDeckHandle? handle,
  }) {
    return _buildRuntime(
      config: config,
      theme: theme,
      extensions: extensions,
      handle: handle,
    );
  }

  static SuperDeckRuntime _buildRuntime({
    required DeckConfig config,
    required DeckTheme theme,
    required List<DeckExtension> extensions,
    SuperDeckHandle? handle,
  }) {
    final slidesPath = switch (config) {
      LocalDeckConfig(:final slidesPath) => slidesPath,
      BundledDeckConfig() => null,
    };

    final configuration = DeckWorkspace(
      projectDir: config.projectDir,
      outputDir: config.outputDir,
      assetsPath: config.assetsPath,
      slidesPath: slidesPath,
    );

    return SuperDeckRuntime._(
      config: config,
      theme: theme,
      extensions: extensions,
      handle: handle ?? SuperDeckHandle(),
      workspace: configuration,
    );
  }

  @internal
  DeckWorkspace get workspace => _workspace;

}
