import 'dart:async';

import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mix/mix.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'tokens/colors.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../runtime/superdeck_runtime.dart';
import '../runtime/bundled_deck_service.dart';
import '../runtime/deck_controller.dart';
import '../runtime/deck_source.dart';
import '../runtime/superdeck_handle.dart';
import '../ui/widgets/provider.dart';
import '../utils/constants.dart';
import '../utils/deck_watcher.dart';
import 'app_shell.dart';
import 'theme.dart';

class SuperDeckApp extends StatelessWidget {
  const SuperDeckApp({super.key, required this.runtime});

  final SuperDeckRuntime runtime;

  @override
  Widget build(BuildContext context) {
    return _RuntimeBootstrap(
      key: ObjectKey(runtime),
      runtime: runtime,
      builder: (context, router) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Superdeck',
          routerConfig: router,
          builder: (context, child) {
            return MixScope(
              colors: SDColors.colorMap,
              child: AppShell(child: child!),
            );
          },
          theme: theme,
        );
      },
    );
  }
}

class _RuntimeBootstrap extends StatefulWidget {
  const _RuntimeBootstrap({
    super.key,
    required this.runtime,
    required this.builder,
  });

  final SuperDeckRuntime runtime;
  final Widget Function(BuildContext context, GoRouter router) builder;

  @override
  State<_RuntimeBootstrap> createState() => _RuntimeBootstrapState();
}

class _RuntimeBootstrapState extends State<_RuntimeBootstrap> {
  late final DeckController _deckController;
  DeckWatcher? _deckWatcher;
  EffectCleanup? _deckWatcherEffect;
  final _logger = Logger('SuperDeckRuntimeBootstrap');

  @override
  void initState() {
    super.initState();

    final configuration = widget.runtime.configuration;
    final deckService = switch (widget.runtime.source) {
      LocalDeckSource() => DeckService(configuration: configuration),
      BundledDeckSource() => BundledDeckService(
        configuration: configuration,
        deckAssetPath: widget.runtime.bundledDeckAssetPath,
      ),
    };

    _deckController = DeckController(
      deckService: deckService,
      presentation: widget.runtime.presentation,
      enableDeckStream: widget.runtime.usesLocalSource && kCanRunProcess,
    );
    widget.runtime.handle.attach(_deckController);

    if (widget.runtime.canWatch && widget.runtime.shouldWatch) {
      try {
        _deckWatcher = DeckWatcher(
          configuration: configuration,
          store: deckService,
        );
        unawaited(_deckWatcher!.start());
        _logger.info('Deck watcher started');

        _deckWatcherEffect = effect(() {
          final isRebuilding = _deckWatcher!.isRebuilding.value;
          _deckController.setRebuilding(isRebuilding);
        });
      } catch (error) {
        _logger.warning('Deck watcher failed to start: $error');
      }
    } else if (!widget.runtime.shouldWatch) {
      _logger.info('Deck watcher disabled via DeckSource.local(watch: false)');
    }
  }

  @override
  void didUpdateWidget(covariant _RuntimeBootstrap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.runtime.presentation != oldWidget.runtime.presentation) {
      _deckController.updatePresentation(widget.runtime.presentation);
    }
    if (!identical(widget.runtime.handle, oldWidget.runtime.handle)) {
      oldWidget.runtime.handle.detach(_deckController);
      widget.runtime.handle.attach(_deckController);
    }
  }

  @override
  void dispose() {
    _deckWatcherEffect?.call();
    _deckWatcher?.dispose();
    widget.runtime.handle.detach(_deckController);
    _deckController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InheritedData<SuperDeckHandle>(
      data: widget.runtime.handle,
      child: InheritedData(
        data: _deckController,
        child: Builder(
          builder: (context) {
            return widget.builder(context, _deckController.router);
          },
        ),
      ),
    );
  }
}
