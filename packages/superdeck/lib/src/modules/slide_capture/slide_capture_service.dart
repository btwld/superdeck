import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:superdeck/src/modules/common/helpers/provider.dart';

import '../../components/atoms/slide_view.dart';
import '../common/helpers/constants.dart';
import '../deck/slide_configuration.dart';

enum SlideCaptureQuality {
  thumbnail(0.3),
  good(1),
  better(2),
  best(3);

  const SlideCaptureQuality(
    this.pixelRatio,
  );

  final double pixelRatio;
}

class SlideCaptureService {
  SlideCaptureService();

  static final _generationQueue = <String>{};
  static const _maxConcurrentGenerations = 3;

  Future<Uint8List> capture({
    SlideCaptureQuality quality = SlideCaptureQuality.thumbnail,
    required SlideConfiguration slide,
    required BuildContext context,
  }) async {
    final queueKey = shortHash(slide.key + quality.name);
    try {
      while (_generationQueue.length > _maxConcurrentGenerations) {
        await Future.delayed(const Duration(milliseconds: 50));
      }

      _generationQueue.add(queueKey);

      final exportingSlide = slide.copyWith(
        debug: false,
        isExporting: true,
      );

      final image = await _fromWidgetToImage(
        InheritedData(
          data: exportingSlide,
          child: SlideView(exportingSlide),
        ),
        // ignore: use_build_context_synchronously
        context: context,
        pixelRatio: quality.pixelRatio,
        targetSize: kResolution,
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

  Future<ui.Image> _fromWidgetToImage(
    Widget widget, {
    required double pixelRatio,
    required BuildContext context,
    Size? targetSize,
  }) async {
    try {
      final child = InheritedTheme.captureAll(
        context,
        MediaQuery(
          data: MediaQuery.of(context),
          child: MaterialApp(
            theme: Theme.of(context),
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: widget),
          ),
        ),
      );

      final repaintBoundary = RenderRepaintBoundary();
      final platformDispatcher = WidgetsBinding.instance.platformDispatcher;

      final view = View.maybeOf(context) ?? platformDispatcher.views.first;
      final logicalSize =
          targetSize ?? view.physicalSize / view.devicePixelRatio;

      int retryCount = 10;
      bool isDirty = false;

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
            maxWidth: logicalSize.width * pixelRatio,
            maxHeight: logicalSize.height * pixelRatio,
          ),
          devicePixelRatio: pixelRatio,
        ),
      );

      final pipelineOwner = PipelineOwner(
        onNeedVisualUpdate: () {
          isDirty = true;
        },
      );

      final buildOwner = BuildOwner(
        focusManager: FocusManager(),
        onBuildScheduled: () {
          isDirty = true;
        },
      );

      pipelineOwner.rootNode = renderView;
      renderView.prepareInitialFrame();

      final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: child,
        ),
      ).attachToRenderTree(buildOwner);

      while (retryCount > 0) {
        isDirty = false;
        buildOwner
          ..buildScope(rootElement)
          ..finalizeTree();

        pipelineOwner
          ..flushLayout()
          ..flushCompositingBits()
          ..flushPaint();

        await Future.delayed(const Duration(milliseconds: 100));

        if (!isDirty) {
          log('Image generation completed.');
          break;
        }

        log('Image generation.. waiting...');

        retryCount--;
      }

      final image = await repaintBoundary.toImage(pixelRatio: pixelRatio);

      buildOwner.finalizeTree();

      return image;
    } catch (e) {
      log('Error finalizing tree: $e');
      rethrow;
    }
  }
}
