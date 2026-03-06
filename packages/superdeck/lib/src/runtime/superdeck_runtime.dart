import 'package:flutter/foundation.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../deck/deck_options.dart';
import '../presentation/deck_presentation.dart';
import '../utils/app_initialization.dart';
import '../utils/constants.dart';
import 'deck_runtime_config.dart';
import 'deck_source.dart';
import 'superdeck_handle.dart';

final class SuperDeckRuntime {
  final DeckSource source;
  final DeckRuntimeConfig runtimeConfig;
  final DeckPresentation presentation;
  final SuperDeckHandle handle;

  final DeckConfiguration _configuration;
  final DeckOptions _options;

  SuperDeckRuntime._({
    required this.source,
    required this.runtimeConfig,
    required this.presentation,
    required this.handle,
    required DeckConfiguration configuration,
    required DeckOptions options,
  }) : _configuration = configuration,
       _options = options;

  static Future<SuperDeckRuntime> create({
    required DeckSource source,
    required DeckRuntimeConfig runtimeConfig,
    required DeckPresentation presentation,
  }) async {
    if (kIsWeb && source is LocalDeckSource) {
      throw UnsupportedError(
        'DeckSource.local is not supported on web runtimes. '
        'Use DeckSource.bundle(...) instead.',
      );
    }

    await initializeDependencies();
    for (final extension in presentation.extensions) {
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
      presentation: presentation,
    );
  }

  @visibleForTesting
  static SuperDeckRuntime forTesting({
    DeckSource source = const DeckSource.bundle(),
    DeckRuntimeConfig runtimeConfig = const DeckRuntimeConfig(),
    DeckPresentation presentation = const DeckPresentation(),
    SuperDeckHandle? handle,
  }) {
    return _buildRuntime(
      source: source,
      runtimeConfig: runtimeConfig,
      presentation: presentation,
      handle: handle,
    );
  }

  static SuperDeckRuntime _buildRuntime({
    required DeckSource source,
    required DeckRuntimeConfig runtimeConfig,
    required DeckPresentation presentation,
    SuperDeckHandle? handle,
  }) {
    final slidesPath = switch (source) {
      LocalDeckSource(:final slidesPath) => slidesPath,
      BundledDeckSource() => null,
    };

    final configuration = runtimeConfig.toDeckConfiguration(
      slidesPath: slidesPath,
    );
    final options = presentation.toDeckOptions(
      watchForChanges: source is LocalDeckSource && source.watch,
    );

    return SuperDeckRuntime._(
      source: source,
      runtimeConfig: runtimeConfig,
      presentation: presentation,
      handle: handle ?? SuperDeckHandle(),
      configuration: configuration,
      options: options,
    );
  }

  @internal
  DeckConfiguration get configuration => _configuration;

  @internal
  DeckOptions get options => _options;

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
