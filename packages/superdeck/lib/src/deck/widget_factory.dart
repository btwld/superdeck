import 'package:flutter/widgets.dart';

/// Factory function that builds a widget from raw block arguments.
///
/// The returned widget is placed in the tree where these are available:
/// - `BlockConfiguration.of(context)` - Block spec, size, and alignment
/// - `SlideConfiguration.of(context)` - Slide configuration
///
/// Simple example:
/// ```dart
/// Widget twitterWidget(Map<String, Object?> args) {
///   final username = args['username'] as String? ?? '';
///   return Text('@$username');
/// }
/// ```
///
/// With typed args and validation:
/// ```dart
/// class ImageWidget extends StatelessWidget {
///   final ImageDto data;
///   ImageWidget(Map<String, Object?> args, {super.key})
///     : data = ImageDto.parse(args);
///
///   @override
///   Widget build(BuildContext context) {
///     final block = BlockConfiguration.of(context);
///     return CachedImage(uri: data.src, targetSize: block.size);
///   }
/// }
///
/// // Register as: 'image': ImageWidget.new
/// ```
typedef WidgetFactory = Widget Function(Map<String, Object?> args);
