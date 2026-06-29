import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../utils/converters.dart';

enum _QrErrorCorrectionToken { low, l, medium, m, high, q, highest, h }

/// Strongly-typed data transfer object for QR code widget.
class QrCodeDto {
  final String text;

  final double size;

  final String errorCorrection;

  final String? backgroundColor;

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
    'text': Ack.string().notEmpty().refine(
      (text) => text.length <= 1000,
      message: 'QR code text must be less than 1000 characters',
    ),
    'size': Ack.double().min(1).max(1000).nullable().optional(),
    'errorCorrection': Ack.enumValues(
      _QrErrorCorrectionToken.values,
    ).nullable().optional(),
    'backgroundColor': Ack.string().nullable().optional().hexColor(),
    'foregroundColor': Ack.string().nullable().optional().hexColor(),
  });

  /// Parses and validates raw map into typed QrCodeDto.
  static QrCodeDto parse(Map<String, Object?> map) {
    final normalized = Map<String, Object?>.from(map);
    if (normalized['size'] case final int size) {
      normalized['size'] = size.toDouble();
    }

    final parsed = schema.parse(normalized)!;
    final errorCorrection =
        parsed['errorCorrection'] as _QrErrorCorrectionToken? ??
        _QrErrorCorrectionToken.medium;

    return QrCodeDto(
      text: parsed['text'] as String,
      size: (parsed['size'] as num?)?.toDouble() ?? 200.0,
      errorCorrection: errorCorrection.name,
      backgroundColor: parsed['backgroundColor'] as String?,
      foregroundColor: parsed['foregroundColor'] as String?,
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
class QrCodeWidget extends StatelessWidget {
  final QrCodeDto _data;

  QrCodeWidget(Map<String, Object?> args, {super.key})
    : _data = QrCodeDto.parse(args);

  @override
  Widget build(BuildContext context) {
    final errorCorrectionLevel = _parseErrorCorrection(_data.errorCorrection);
    final backgroundColor = _data.backgroundColor != null
        ? hexToColor(_data.backgroundColor!)
        : Colors.white;
    final foregroundColor = _data.foregroundColor != null
        ? hexToColor(_data.foregroundColor!)
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
          data: _data.text,
          version: QrVersions.auto,
          size: _data.size,
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
}

int _parseErrorCorrection(String level) {
  return switch (level.toLowerCase()) {
    'low' || 'l' => QrErrorCorrectLevel.L,
    'medium' || 'm' => QrErrorCorrectLevel.M,
    'high' || 'q' => QrErrorCorrectLevel.Q,
    'highest' || 'h' => QrErrorCorrectLevel.H,
    _ => QrErrorCorrectLevel.M,
  };
}
