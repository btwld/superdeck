import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Scaffold, Theme;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../builtins/image_widget.dart';
import '../builtins/widgets.dart';
import '../deck/slide_configuration.dart';
import '../markdown/builders/image_element_builder.dart' show isBareAssetKey;
import '../rendering/slides/slide_view.dart';
import '../ui/tokens/colors.dart';
import '../ui/widgets/cache_image_widget.dart';
import '../ui/widgets/provider.dart';
import '../utils/constants.dart';
import 'capture_limiter.dart';
import 'render_config.dart';
import 'slide_capture_readiness.dart';

enum SlideCaptureQuality {
  thumbnail(0.3),
  good(1),
  better(2),
  best(3);

  const SlideCaptureQuality(this.pixelRatio);

  final double pixelRatio;
}

class SlideCaptureService {
  SlideCaptureService();

  final _captureLimiter = CaptureLimiter(_maxConcurrentGenerations);

  /// Maximum concurrent generations to prevent memory pressure.
  static const _maxConcurrentGenerations = 3;
  static const _kRenderSettleDelay = Duration(milliseconds: 32);
  static const _kMaxRenderPasses = 30;
  static const _kRequiredStablePasses = 2;
  static const _kImageDecodeTimeout = Duration(seconds: 1);

  Future<Uint8List> capture({
    SlideCaptureQuality quality = SlideCaptureQuality.thumbnail,
    required SlideConfiguration slide,
    required BuildContext context,
    bool includeDebugLayout = false,
  }) async {
    await _captureLimiter.acquire();
    try {
      var staticRenderingSlide = slide.copyWith(
        debug: includeDebugLayout,
        isStaticRendering: true,
      );

      // Check if the context is still mounted after the async gap
      if (!context.mounted) {
        throw Exception('BuildContext is no longer mounted');
      }

      final imageConfiguration = createLocalImageConfiguration(context);
      final decodedImages = await _decodeBuiltInImages(
        staticRenderingSlide,
        imageConfiguration,
      );
      if (!context.mounted) {
        for (final image in decodedImages.values) {
          image.dispose();
        }
        throw Exception('BuildContext is no longer mounted');
      }
      if (decodedImages.isNotEmpty) {
        final originalImageFactory = staticRenderingSlide.widgets['image']!;
        staticRenderingSlide = staticRenderingSlide.copyWith(
          widgets: {
            ...staticRenderingSlide.widgets,
            'image': (args) {
              final src = (args['src'] as String?)?.trim();
              final decodedImage = decodedImages[src];
              return decodedImage == null
                  ? originalImageFactory(args)
                  : ImageWidget(args, decodedImage: decodedImage);
            },
          },
        );
      }

      final config = RenderConfig(
        pixelRatio: quality.pixelRatio,
        context: context,
        targetSize: kResolution,
      );

      try {
        final image = await _fromWidgetToImage(
          InheritedData(
            data: staticRenderingSlide,
            child: SlideView(staticRenderingSlide),
          ),
          config,
        );

        return await _imageToUint8List(image);
      } finally {
        for (final image in decodedImages.values) {
          image.dispose();
        }
      }
    } catch (e, stackTrace) {
      log('Error generating image: $e', stackTrace: stackTrace);
      rethrow;
    } finally {
      _captureLimiter.release();
    }
  }

  Future<Map<String, ui.Image>> _decodeBuiltInImages(
    SlideConfiguration slide,
    ImageConfiguration imageConfiguration,
  ) async {
    if (slide.widgets['image'] != builtInWidgets['image']) return const {};

    final sources = <String>{};
    for (final section in slide.sections) {
      for (final block in section.blocks) {
        if (block is! WidgetBlock || block.name != 'image') continue;
        final source = block.args['src'];
        if (source is String && source.trim().isNotEmpty) {
          sources.add(source.trim());
        }
      }
    }
    if (sources.isEmpty) return const {};

    final entries = await Future.wait(
      sources.map((source) async {
        try {
          final data = ImageDto.parse({'src': source});
          final uri = isBareAssetKey(data.src)
              ? await slide.assetCacheStore?.resolve(data.src.path)
              : data.src;
          if (uri == null) return null;

          final image = await _decodeImage(
            getImageProvider(uri),
            imageConfiguration,
          );
          return image == null ? null : MapEntry(source, image);
        } catch (_) {
          return null;
        }
      }),
    );

    return Map.fromEntries(entries.whereType<MapEntry<String, ui.Image>>());
  }

  Future<ui.Image?> _decodeImage(
    ImageProvider<Object> provider,
    ImageConfiguration imageConfiguration,
  ) async {
    final stream = provider.resolve(imageConfiguration);
    final completer = Completer<ui.Image?>();
    final listener = ImageStreamListener(
      (info, _) {
        if (!completer.isCompleted) {
          completer.complete(info.image.clone());
        }
      },
      onError: (_, _) {
        if (!completer.isCompleted) completer.complete(null);
      },
    );
    stream.addListener(listener);
    try {
      return await completer.future.timeout(
        _kImageDecodeTimeout,
        onTimeout: () => null,
      );
    } finally {
      stream.removeListener(listener);
    }
  }

  Future<Uint8List> captureFromKey({
    required GlobalKey key,
    required SlideCaptureQuality quality,
  }) async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;

    // Get the size of the boundary
    final boundarySize = boundary.size;
    //  adjust the pixel ratio based on the ideal size which is kResolution
    final pixelRatio = kResolution.width / boundarySize.width;

    final image = await boundary.toImage(
      pixelRatio: quality.pixelRatio * pixelRatio,
    );
    return _imageToUint8List(image);
  }

  Future<Uint8List> _imageToUint8List(ui.Image image) async {
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// Converts a Flutter widget to a [ui.Image] via an isolated render pipeline.
  ///
  /// Sets up a complete render context (theme, media query, material app),
  /// drives a bounded settle loop for async/delayed widgets, then rasterises.
  /// Releases the temporary element, render, and focus resources on success,
  /// on the settle limit, and on failure.
  Future<ui.Image> _fromWidgetToImage(
    Widget widget,
    RenderConfig config,
  ) async {
    RenderRepaintBoundary? repaintBoundary;
    RenderPositionedBox? rootBox;
    RenderView? renderView;
    PipelineOwner? pipelineOwner;
    FocusManager? focusManager;
    BuildOwner? buildOwner;
    RenderObjectToWidgetElement<RenderBox>? rootElement;

    try {
      final mixScope = MixScope.maybeOf(config.context);
      final readiness = SlideCaptureReadiness();
      final child = readiness.bind(
        InheritedTheme.captureAll(
          config.context,
          MediaQuery(
            data: MediaQuery.of(config.context),
            child: Localizations.override(
              context: config.context,
              child: Theme(
                data: Theme.of(config.context),
                child: Scaffold(
                  body: MixScope(
                    tokens: {...?mixScope?.tokens, ...SDColors.colorMap},
                    child: widget,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      repaintBoundary = RenderRepaintBoundary();
      rootBox = RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      );
      final platformDispatcher = WidgetsBinding.instance.platformDispatcher;

      final view =
          View.maybeOf(config.context) ?? platformDispatcher.views.first;
      final logicalSize =
          config.targetSize ?? view.physicalSize / view.devicePixelRatio;
      final physicalSize = logicalSize * config.pixelRatio;

      renderView = RenderView(
        view: view,
        child: rootBox,
        configuration: ViewConfiguration(
          logicalConstraints: BoxConstraints.tight(logicalSize),
          physicalConstraints: BoxConstraints.tight(physicalSize),
          devicePixelRatio: config.pixelRatio,
        ),
      );

      var isDirty = false;
      pipelineOwner = PipelineOwner(onNeedVisualUpdate: () => isDirty = true);
      focusManager = FocusManager();
      buildOwner = BuildOwner(
        focusManager: focusManager,
        onBuildScheduled: () => isDirty = true,
      );

      pipelineOwner.rootNode = renderView;
      renderView.prepareInitialFrame();

      rootElement = RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,
        child: Directionality(textDirection: TextDirection.ltr, child: child),
      ).attachToRenderTree(buildOwner);

      var settled = false;
      var stablePasses = 0;
      for (var pass = 0; pass < _kMaxRenderPasses; pass++) {
        isDirty = false;

        buildOwner
          ..buildScope(rootElement)
          ..finalizeTree();

        pipelineOwner
          ..flushLayout()
          ..flushCompositingBits()
          ..flushPaint();

        await Future<void>.delayed(_kRenderSettleDelay);

        if (isDirty || !readiness.isReady) {
          stablePasses = 0;
          continue;
        }

        stablePasses++;
        if (stablePasses >= _kRequiredStablePasses) {
          settled = true;
          break;
        }
      }

      if (!settled) {
        final pendingLabels = readiness.pendingLabels.join(', ');
        final pendingDetails = pendingLabels.isEmpty
            ? ''
            : ' Pending: $pendingLabels.';
        log(
          'Slide capture reached the settle limit with '
          '${readiness.pendingCount} readiness task(s) pending. '
          'Capturing the last rendered frame.$pendingDetails',
        );
      }

      final image = await repaintBoundary.toImage(
        pixelRatio: config.pixelRatio,
      );

      buildOwner.finalizeTree();

      return image;
    } catch (e) {
      log('Error finalizing tree: $e');
      rethrow;
    } finally {
      _releaseCaptureTree(
        buildOwner: buildOwner,
        rootElement: rootElement,
        repaintBoundary: repaintBoundary,
        rootBox: rootBox,
        renderView: renderView,
        pipelineOwner: pipelineOwner,
        focusManager: focusManager,
      );
    }
  }

  /// Unmounts the temporary capture subtree and releases its owned resources.
  ///
  /// Rebuilding the root adapter without a child deactivates the captured
  /// widgets, and [BuildOwner.finalizeTree] then unmounts them so their
  /// [State.dispose] and render object disposal run. The render pipeline,
  /// the render objects this service created, and the focus manager are
  /// released afterwards.
  void _releaseCaptureTree({
    required BuildOwner? buildOwner,
    required RenderObjectToWidgetElement<RenderBox>? rootElement,
    required RenderRepaintBoundary? repaintBoundary,
    required RenderPositionedBox? rootBox,
    required RenderView? renderView,
    required PipelineOwner? pipelineOwner,
    required FocusManager? focusManager,
  }) {
    if (buildOwner != null && rootElement != null && repaintBoundary != null) {
      try {
        RenderObjectToWidgetAdapter<RenderBox>(
          container: repaintBoundary,
        ).attachToRenderTree(buildOwner, rootElement);
        buildOwner
          ..buildScope(rootElement)
          ..finalizeTree();
      } catch (e, stackTrace) {
        log('Error unmounting capture tree: $e', stackTrace: stackTrace);
      }
    }

    if (pipelineOwner != null) {
      pipelineOwner.rootNode = null;
      pipelineOwner.dispose();
    }

    repaintBoundary?.dispose();
    rootBox?.dispose();
    renderView?.dispose();

    if (focusManager != null) {
      // Unmounting focus nodes schedules a focus update microtask. Disposing
      // in a later microtask lets that update run against a live manager.
      scheduleMicrotask(focusManager.dispose);
    }
  }
}
