import 'package:flutter/widgets.dart';

/// Abstract base class for custom widget blocks with typed, schema-validated arguments.
///
/// Custom widgets extend this class and implement [build] to render their content.
/// The type parameter [T] represents the strongly-typed arguments class.
///
/// Example with typed arguments:
/// ```dart
/// class QrCodeArgs {
///   final String text;
///   final double size;
///
///   const QrCodeArgs({required this.text, this.size = 200.0});
///
///   static final schema = Ack.object({
///     'text': Ack.string(),
///     'size': Ack.double().nullable().optional(),
///   });
///
///   static QrCodeArgs parse(Map<String, Object?> map) {
///     schema.parse(map); // Validate first
///     return QrCodeArgs(
///       text: map['text'] as String,
///       size: (map['size'] as num?)?.toDouble() ?? 200.0,
///     );
///   }
/// }
///
/// class QrCodeWidget extends WidgetDefinition<QrCodeArgs> {
///   const QrCodeWidget();
///
///   @override
///   QrCodeArgs parse(Map<String, Object?> args) => QrCodeArgs.parse(args);
///
///   @override
///   Widget build(BuildContext context, QrCodeArgs args) {
///     return QrImageView(data: args.text, size: args.size);
///   }
/// }
/// ```
abstract class WidgetDefinition<T> {
  const WidgetDefinition();

  /// Parses and validates raw arguments into a strongly-typed instance.
  ///
  /// Implementations should:
  /// 1. Validate the map using a schema
  /// 2. Parse values and construct the typed args object
  /// 3. Throw descriptive errors if validation fails
  ///
  /// Example:
  /// ```dart
  /// @override
  /// QrCodeArgs parse(Map<String, Object?> args) {
  ///   QrCodeArgs.schema.parse(args); // Validate
  ///   return QrCodeArgs.fromMap(args); // Parse
  /// }
  /// ```
  T parse(Map<String, Object?> args);

  /// Builds the widget with strongly-typed, validated arguments.
  ///
  /// The framework calls [parse] to validate and convert raw arguments
  /// before calling this method, ensuring [args] is always valid and typed.
  ///
  /// The [context] provides access to:
  /// - `BlockData.of(context)` - Block spec, size, and block data
  /// - `SlideConfiguration.of(context)` - Slide configuration
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Widget build(BuildContext context, QrCodeArgs args) {
  ///   final data = BlockData.of(context);
  ///   return SizedBox(
  ///     width: data.size.width,
  ///     height: data.size.height,
  ///     child: Center(child: QrImageView(data: args.text, size: args.size)),
  ///   );
  /// }
  /// ```
  Widget build(BuildContext context, T args);
}
