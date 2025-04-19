import 'dart:io' as io;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Utilities for platform-specific functionality
class PlatformUtils {
  /// Whether the current platform is web
  static bool get isWeb => kIsWeb;

  /// Whether the current platform is desktop (Windows, macOS, Linux)
  static bool get isDesktop {
    if (kIsWeb) return false;
    return io.Platform.isWindows || io.Platform.isMacOS || io.Platform.isLinux;
  }

  /// Whether the current platform is mobile (iOS, Android)
  static bool get isMobile {
    if (kIsWeb) return false;
    return io.Platform.isIOS || io.Platform.isAndroid;
  }

  /// Whether the current platform is macOS
  static bool get isMacOS {
    if (kIsWeb) return false;
    return io.Platform.isMacOS;
  }

  /// Whether the current platform is Windows
  static bool get isWindows {
    if (kIsWeb) return false;
    return io.Platform.isWindows;
  }

  /// Whether the current platform is Linux
  static bool get isLinux {
    if (kIsWeb) return false;
    return io.Platform.isLinux;
  }
}
