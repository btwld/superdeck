import 'package:flutter/foundation.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../presentation/deck_extension.dart';
import '../presentation/deck_theme.dart';
import '../utils/app_initialization.dart';
import '../utils/constants.dart';
import 'deck_runtime_config.dart';
import 'deck_source.dart';
import 'superdeck_handle.dart';

final class SuperDeckRuntime {
  final DeckSource source;
  final DeckRuntimeConfig runtimeConfig;
  final DeckTheme theme;
  final List<DeckExtension> extensions;
  final SuperDeckHandle handle;

  final DeckWorkspace _workspace;

  SuperDeckRuntime._({
    required this.source,
    required this.runtimeConfig,
    required this.theme,
    required this.extensions,
    required this.handle,
    required DeckWorkspace workspace,
  }) : _workspace = workspace;

  static Future<SuperDeckRuntime> create({
    required DeckSource source,
    DeckRuntimeConfig runtimeConfig = const DeckRuntimeConfig(),
    DeckTheme theme = const DeckTheme(),
    List<DeckExtension> extensions = const <DeckExtension>[],
  }) async {
    if (kIsWeb && source is LocalDeckSource) {
      throw UnsupportedError(
        'DeckSource.local is not supported on web runtimes. '
        'Use DeckSource.bundle(...) instead.',
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

    return _buildRuntime(
      source: source,
      runtimeConfig: runtimeConfig,
      theme: theme,
      extensions: extensions,
    );
  }

  @visibleForTesting
  static SuperDeckRuntime forTesting({
    DeckSource source = const DeckSource.bundle(),
    DeckRuntimeConfig runtimeConfig = const DeckRuntimeConfig(),
    DeckTheme theme = const DeckTheme(),
    List<DeckExtension> extensions = const <DeckExtension>[],
    SuperDeckHandle? handle,
  }) {
    return _buildRuntime(
      source: source,
      runtimeConfig: runtimeConfig,
      theme: theme,
      extensions: extensions,
      handle: handle,
    );
  }

  static SuperDeckRuntime _buildRuntime({
    required DeckSource source,
    required DeckRuntimeConfig runtimeConfig,
    required DeckTheme theme,
    required List<DeckExtension> extensions,
    SuperDeckHandle? handle,
  }) {
    final slidesPath = switch (source) {
      LocalDeckSource(:final slidesPath) => slidesPath,
      BundledDeckSource() => null,
    };

    final configuration = DeckWorkspace(
      projectDir: runtimeConfig.projectDir,
      outputDir: runtimeConfig.outputDir,
      assetsPath: runtimeConfig.assetsPath,
      slidesPath: slidesPath,
    );

    return SuperDeckRuntime._(
      source: source,
      runtimeConfig: runtimeConfig,
      theme: theme,
      extensions: extensions,
      handle: handle ?? SuperDeckHandle(),
      workspace: configuration,
    );
  }

  @internal
  DeckWorkspace get workspace => _workspace;

  @internal
  bool get shouldWatch => switch (source) {
    LocalDeckSource(:final watch) => watch,
    BundledDeckSource() => false,
  };

  @internal
  bool get canWatch => source is LocalDeckSource && kCanRunProcess;

  @internal
  bool get usesLocalSource => source is LocalDeckSource;

  @internal
  String get bundledDeckAssetPath => switch (source) {
    BundledDeckSource(:final deckAssetPath) => deckAssetPath,
    _ => DeckArtifacts.bundledDeckAssetPath,
  };
}
