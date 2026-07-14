import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show MaterialApp, Scaffold, Theme;
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:mix/mix.dart';
import 'package:superdeck_core/superdeck_core.dart' show WidgetBlock;
import '../ui/tokens/colors.dart';
import '../ui/widgets/provider.dart';

import '../rendering/slides/slide_view.dart';
import '../utils/constants.dart';
import '../deck/slide_configuration.dart';
import 'render_config.dart';

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
  static const _kImageMinimumRenderPasses = 16;

  Future<Uint8List> capture({
    SlideCaptureQuality quality = SlideCaptureQuality.thumbnail,
    required SlideConfiguration slide,
    required BuildContext context,
  }) async {
    final queueKey = shortHash(slide.key + quality.name);
    try {
      while (_generationQueue.length >= _maxConcurrentGenerations) {
        await Future.delayed(_kQueuePollInterval);
      }

      _generationQueue.add(queueKey);

      final staticRenderingSlide = slide.copyWith(
        debug: false,
        isStaticRendering: true,
      );

      // Check if the context is still mounted after the async gap
      if (!context.mounted) {
        throw Exception('BuildContext is no longer mounted');
      }

      final config = RenderConfig(
        pixelRatio: quality.pixelRatio,
        context: context,
        targetSize: kResolution,
        minimumRenderPasses: _containsImageWidget(staticRenderingSlide)
            ? _kImageMinimumRenderPasses
            : 0,
      );

      final image = await _fromWidgetToImage(
        InheritedData(
          data: staticRenderingSlide,
          child: SlideView(staticRenderingSlide),
        ),
        config,
      );

      return _imageToUint8List(image);
    } catch (e, stackTrace) {
      log('Error generating image: $e', stackTrace: stackTrace);
      rethrow;
    } finally {
      _generationQueue.remove(queueKey);
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

  bool _containsImageWidget(SlideConfiguration slide) {
    return slide.sections.any(
      (section) => section.blocks.any(
        (block) => block is WidgetBlock && block.name == 'image',
      ),
    );
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
      final child = InheritedTheme.captureAll(
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

        if (isDirty) {
          stablePasses = 0;
          continue;
        }

        stablePasses++;
        if (pass + 1 >= config.minimumRenderPasses &&
            stablePasses >= _kRequiredStablePasses) {
          settled = true;
          break;
        }
      }

      if (!settled) {
        log(
          'Slide capture reached the settle limit. Capturing the last rendered frame.',
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
