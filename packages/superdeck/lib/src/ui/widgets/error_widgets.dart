import 'package:flutter/material.dart' show Icons, Colors;
import 'package:flutter/widgets.dart';
import 'package:superdeck/src/ui/widgets/button.dart';

/// Simple error widget helpers to reduce duplication across the codebase
/// Follows DRY principle by centralizing error UI patterns
class ErrorWidgets {
  /// Simple error container with red background and centered text
  /// Used for basic error states like image loading failures
  static Widget simple(String message) {
    return Container(
      color: Colors.red,
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Detailed error container with padding, border, and structured layout
  /// Used for widget building errors and other complex error states
  static Widget detailed(String title, String details) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red,
        border: Border.all(color: Colors.red, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '$title\n\n$details',
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Error widget with retry functionality
  /// Used for recoverable errors like thumbnail generation failures
  static Widget withRetry(String message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 40),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          SDButton(onPressed: onRetry, label: 'Retry', icon: Icons.refresh),
        ],
      ),
    );
  }
}
