import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show MaterialApp, Scaffold, Theme;
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
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

      final exportingSlide = slide.copyWith(debug: false, isExporting: true);

      // Check if the context is still mounted after the async gap
      if (!context.mounted) {
        throw Exception('BuildContext is no longer mounted');
      }

      final config = RenderConfig(
        pixelRatio: quality.pixelRatio,
        context: context,
        targetSize: kResolution,
      );

      final image = await _fromWidgetToImage(
        InheritedData(data: exportingSlide, child: SlideView(exportingSlide)),
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

  Future<Uint8List> _imageToUint8List(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData!.buffer.asUint8List();
  }

  /// Converts a Flutter widget to a [ui.Image] via an isolated render pipeline.
  ///
  /// Sets up a complete render context (theme, media query, material app),
  /// builds and lays out the tree in a single pass, then rasterises.
  Future<ui.Image> _fromWidgetToImage(
    Widget widget,
    RenderConfig config,
  ) async {
    try {
      final child = InheritedTheme.captureAll(
        config.context,
        MediaQuery(
          data: MediaQuery.of(config.context),
          child: MaterialApp(
            theme: Theme.of(config.context),
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: widget),
          ),
        ),
      );

      final repaintBoundary = RenderRepaintBoundary();
      final platformDispatcher = WidgetsBinding.instance.platformDispatcher;

      final view =
          View.maybeOf(config.context) ?? platformDispatcher.views.first;
      final logicalSize =
          config.targetSize ?? view.physicalSize / view.devicePixelRatio;

      final renderView = RenderView(
        view: view,
        child: RenderPositionedBox(
          alignment: Alignment.center,
          child: repaintBoundary,
        ),
        configuration: ViewConfiguration(
          logicalConstraints: BoxConstraints(
            maxWidth: logicalSize.width,
            maxHeight: logicalSize.height,
          ),
          physicalConstraints: BoxConstraints(
            maxWidth: logicalSize.width * config.pixelRatio,
            maxHeight: logicalSize.height * config.pixelRatio,
          ),
          devicePixelRatio: config.pixelRatio,
        ),
      );

      final pipelineOwner = PipelineOwner();
      final buildOwner = BuildOwner(focusManager: FocusManager());

      pipelineOwner.rootNode = renderView;
      renderView.prepareInitialFrame();

      final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,
        child: Directionality(textDirection: TextDirection.ltr, child: child),
      ).attachToRenderTree(buildOwner);

      buildOwner
        ..buildScope(rootElement)
        ..finalizeTree();

      pipelineOwner
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();

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
