import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../deck/widget_definition.dart';
import '../utils/converters.dart';

/// Strongly-typed data transfer object for QR code widget.
class QrCodeDto {
  /// The data to encode in the QR code.
  final String text;

  /// Size of the QR code in logical pixels.
  final double size;

  /// Error correction level (low, medium, high, or highest).
  final String errorCorrection;

  /// Hex color for background.
  final String? backgroundColor;

  /// Hex color for QR code.
  final String? foregroundColor;

  const QrCodeDto({
    required this.text,
    this.size = 200.0,
    this.errorCorrection = 'medium',
    this.backgroundColor,
    this.foregroundColor,
  });

  /// Schema for validating QR code arguments with comprehensive validation.
  static final schema = Ack.object({
    'text': Ack.string()
        .notEmpty()
        .refine(
          (text) => text.length <= 1000,
          message: 'QR code text must be less than 1000 characters',
        ),
    'size': Ack.double()
        .min(1)
        .max(1000)
        .nullable()
        .optional(),
    'errorCorrection': Ack.string()
        .enumString(['low', 'l', 'medium', 'm', 'high', 'q', 'highest', 'h'])
        .nullable()
        .optional(),
    'backgroundColor': Ack.string()
        .nullable()
        .optional()
        .hexColor(),
    'foregroundColor': Ack.string()
        .nullable()
        .optional()
        .hexColor(),
  });

  /// Parses and validates raw map into typed QrCodeDto.
  static QrCodeDto parse(Map<String, Object?> map) {
    schema.parse(map); // Validate first
    return QrCodeDto(
      text: map['text'] as String,
      size: (map['size'] as num?)?.toDouble() ?? 200.0,
      errorCorrection: map['errorCorrection'] as String? ?? 'medium',
      backgroundColor: map['backgroundColor'] as String?,
      foregroundColor: map['foregroundColor'] as String?,
    );
  }
}

/// Built-in widget for rendering QR codes in presentations.
///
/// Usage in slides.md:
/// ```markdown
/// @qrcode {
///   text: "https://example.com"
///   size: 200
///   errorCorrection: high
///   backgroundColor: "#ffffff"
///   foregroundColor: "#000000"
/// }
/// ```
///
/// Parameters:
/// - `text` (required): The data to encode in the QR code
/// - `size` (optional): Size of the QR code in logical pixels (default: 200)
/// - `errorCorrection` (optional): Error correction level - low, medium, high, or highest (default: medium)
/// - `backgroundColor` (optional): Hex color for background (default: white)
/// - `foregroundColor` (optional): Hex color for QR code (default: black)
class QrCodeWidget extends WidgetDefinition<QrCodeDto> {
  const QrCodeWidget();

  @override
  QrCodeDto parse(Map<String, Object?> args) => QrCodeDto.parse(args);

  @override
  Widget build(BuildContext context, QrCodeDto args) {
    // Parse optional parameters with defaults
    final errorCorrectionLevel = _parseErrorCorrection(args.errorCorrection);
    final backgroundColor = args.backgroundColor != null
        ? hexToColor(args.backgroundColor!)
        : Colors.white;
    final foregroundColor = args.foregroundColor != null
        ? hexToColor(args.foregroundColor!)
        : Colors.black;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: QrImageView(
          data: args.text,
          version: QrVersions.auto,
          size: args.size,
          errorCorrectionLevel: errorCorrectionLevel,
          backgroundColor: backgroundColor,
          eyeStyle: QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: foregroundColor,
          ),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: foregroundColor,
          ),
        ),
      ),
    );
  }

  /// Parses error correction level from string.
  int _parseErrorCorrection(String level) {
    return switch (level.toLowerCase()) {
      'low' || 'l' => QrErrorCorrectLevel.L,
      'medium' || 'm' => QrErrorCorrectLevel.M,
      'high' || 'q' => QrErrorCorrectLevel.Q,
      'highest' || 'h' => QrErrorCorrectLevel.H,
      _ => QrErrorCorrectLevel.M,
    };
  }
}
