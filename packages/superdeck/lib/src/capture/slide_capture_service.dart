import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show MaterialApp, Scaffold, Theme;
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

  /// Queue of slide keys currently being generated.
  /// Instance-level to prevent interference between service instances.
  final _generationQueue = <String>{};

  /// Maximum concurrent generations to prevent memory pressure.
  static const _maxConcurrentGenerations = 3;
  static const _kQueuePollInterval = Duration(milliseconds: 50);
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
    final queueKey = shortHash(
      '${slide.key}${quality.name}$includeDebugLayout',
    );
    try {
      while (_generationQueue.length >= _maxConcurrentGenerations) {
        await Future.delayed(_kQueuePollInterval);
      }

      _generationQueue.add(queueKey);

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

        return _imageToUint8List(image);
      } finally {
        for (final image in decodedImages.values) {
          image.dispose();
        }
      }
    } catch (e, stackTrace) {
      log('Error generating image: $e', stackTrace: stackTrace);
      rethrow;
    } finally {
      _generationQueue.remove(queueKey);
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
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData!.buffer.asUint8List();
  }

  /// Converts a Flutter widget to a [ui.Image] via an isolated render pipeline.
  ///
  /// Sets up a complete render context (theme, media query, material app),
  /// drives a bounded settle loop for async/delayed widgets, then rasterises.
  Future<ui.Image> _fromWidgetToImage(
    Widget widget,
    RenderConfig config,
  ) async {
    try {
      final mixScope = MixScope.maybeOf(config.context);
      final readiness = SlideCaptureReadiness();
      final child = readiness.bind(
        InheritedTheme.captureAll(
          config.context,
          MediaQuery(
            data: MediaQuery.of(config.context),
            child: MaterialApp(
              theme: Theme.of(config.context),
              debugShowCheckedModeBanner: false,

              home: Scaffold(
                body: MixScope(
                  tokens: {...?mixScope?.tokens, ...SDColors.colorMap},
                  child: widget,
                ),
              ),
            ),
          ),
        ),
      );

      final repaintBoundary = RenderRepaintBoundary();
      final platformDispatcher = WidgetsBinding.instance.platformDispatcher;

      final view =
          View.maybeOf(config.context) ?? platformDispatcher.views.first;
      final logicalSize =
          config.targetSize ?? view.physicalSize / view.devicePixelRatio;
      final physicalSize = logicalSize * config.pixelRatio;

      final renderView = RenderView(
        view: view,
        child: RenderPositionedBox(
          alignment: Alignment.center,
          child: repaintBoundary,
        ),
        configuration: ViewConfiguration(
          logicalConstraints: BoxConstraints.tight(logicalSize),
          physicalConstraints: BoxConstraints.tight(physicalSize),
          devicePixelRatio: config.pixelRatio,
        ),
      );

      var isDirty = false;
      final pipelineOwner = PipelineOwner(
        onNeedVisualUpdate: () => isDirty = true,
      );
      final buildOwner = BuildOwner(
        focusManager: FocusManager(),
        onBuildScheduled: () => isDirty = true,
      );

      pipelineOwner.rootNode = renderView;
      renderView.prepareInitialFrame();

      final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
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
    }
  }
}
