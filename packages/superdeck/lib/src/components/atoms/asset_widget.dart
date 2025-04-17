import 'dart:io';

import 'package:flutter/material.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../modules/assets/asset_service.dart';
import '../../modules/deck/slide_configuration.dart';
import 'loading_indicator.dart';

/// Widget for displaying any type of asset
class AssetWidget extends StatelessWidget {
  final Asset asset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, Object)? errorBuilder;

  const AssetWidget({
    super.key,
    required this.asset,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final assetService = AssetService.of(context);

    return FutureBuilder<AssetSource>(
      future: assetService.storage.getAssetSource(asset),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: IsometricLoading(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorWidget(context, snapshot.error);
        }

        final source = snapshot.data!;
        return _buildImageFromSource(context, source);
      },
    );
  }

  Widget _buildImageFromSource(BuildContext context, AssetSource source) {
    ImageErrorWidgetBuilder? imageErrorBuilder;
    if (errorBuilder != null) {
      imageErrorBuilder =
          (context, error, stackTrace) => errorBuilder!(context, error);
    }

    Widget imageWidget;

    switch (source.type) {
      case AssetSourceType.file:
        imageWidget = Image.file(
          File(source.path),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: imageErrorBuilder,
        );
        break;
      case AssetSourceType.bundle:
        imageWidget = Image.asset(
          source.path,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: imageErrorBuilder,
        );
        break;
      case AssetSourceType.memory:
        if (source.bytes == null || source.bytes!.isEmpty) {
          return _buildErrorWidget(context, "Empty image data");
        }
        imageWidget = Image.memory(
          source.bytes!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: imageErrorBuilder,
        );
        break;
      case AssetSourceType.url:
        imageWidget = Image.network(
          source.path,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: imageErrorBuilder,
        );
        break;
    }

    return imageWidget;
  }

  Widget _buildErrorWidget(BuildContext context, Object? error) {
    if (errorBuilder != null) {
      return errorBuilder!(context, error ?? "Failed to load image");
    }

    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? "Failed to load image",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget specifically for displaying slide thumbnails
class ThumbnailWidget extends StatelessWidget {
  final SlideConfiguration slide;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool enableRefresh;
  final VoidCallback? onTap;

  const ThumbnailWidget({
    super.key,
    required this.slide,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.enableRefresh = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final assetService = AssetService.of(context);

    return FutureBuilder<AssetSource>(
      future: assetService.getThumbnail(
        slide: slide,
        context: context,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: IsometricLoading(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorWidget(context, snapshot.error, assetService);
        }

        final source = snapshot.data!;
        return _buildThumbnailFromSource(context, source);
      },
    );
  }

  Widget _buildThumbnailFromSource(BuildContext context, AssetSource source) {
    ImageFrameBuilder? imageFrameBuilder;
    if (onTap != null) {
      imageFrameBuilder = (context, child, frame, _) {
        return GestureDetector(
          onTap: onTap,
          child: child,
        );
      };
    }

    thumbnailErrorBuilder(context, error, stackTrace) => _buildErrorWidget(
          context,
          error,
          AssetService.of(context),
        );

    Widget thumbnailWidget;

    switch (source.type) {
      case AssetSourceType.file:
        thumbnailWidget = Image.file(
          File(source.path),
          width: width,
          height: height,
          fit: fit,
          frameBuilder: imageFrameBuilder,
          errorBuilder: thumbnailErrorBuilder,
        );
        break;
      case AssetSourceType.bundle:
        thumbnailWidget = Image.asset(
          source.path,
          width: width,
          height: height,
          fit: fit,
          frameBuilder: imageFrameBuilder,
          errorBuilder: thumbnailErrorBuilder,
        );
        break;
      case AssetSourceType.memory:
        if (source.bytes == null || source.bytes!.isEmpty) {
          return _buildErrorWidget(
            context,
            "Empty image data",
            AssetService.of(context),
          );
        }
        thumbnailWidget = Image.memory(
          source.bytes!,
          width: width,
          height: height,
          fit: fit,
          frameBuilder: imageFrameBuilder,
          errorBuilder: thumbnailErrorBuilder,
        );
        break;
      case AssetSourceType.url:
        thumbnailWidget = Image.network(
          source.path,
          width: width,
          height: height,
          fit: fit,
          frameBuilder: imageFrameBuilder,
          errorBuilder: thumbnailErrorBuilder,
        );
        break;
    }

    return thumbnailWidget;
  }

  Widget _buildErrorWidget(
    BuildContext context,
    Object? error,
    AssetService assetService,
  ) {
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 30,
            ),
            const SizedBox(height: 8),
            if (enableRefresh)
              ElevatedButton.icon(
                onPressed: () async {
                  await assetService.getThumbnail(
                    slide: slide,
                    context: context,
                    force: true,
                  );
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
          ],
        ),
      ),
    );
  }
}
