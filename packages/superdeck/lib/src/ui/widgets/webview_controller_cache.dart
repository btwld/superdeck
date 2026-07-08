import 'package:webview_flutter/webview_flutter.dart';

/// Mutable navigation policy shared between a cached controller and the active
/// [WebViewWrapper] mount so host rules stay current after URL changes.
class WebViewNavigationPolicy {
  Set<String> allowedHosts = {};

  NavigationDecision decide(NavigationRequest request) {
    final requestHost = Uri.tryParse(request.url)?.host;
    if (requestHost != null && allowedHosts.contains(requestHost)) {
      return NavigationDecision.navigate;
    }
    return NavigationDecision.prevent;
  }
}

/// One cached [WebViewController] plus the last loaded URL and live callbacks.
class CachedWebViewEntry {
  final WebViewController controller;
  final policy = WebViewNavigationPolicy();

  /// Last URL successfully requested for this entry.
  String? loadedUrl;

  /// Active mount listens here for page-finished fade-in.
  void Function()? onPageFinished;

  /// Whether the platform can report page-finished events for this controller.
  bool pageFinishedCallbacksUnsupported = false;

  Object? _activeMount;

  CachedWebViewEntry({required this.controller});

  bool activate(Object mount) {
    if (_activeMount == null || identical(_activeMount, mount)) {
      _activeMount = mount;
      return true;
    }
    return false;
  }

  void release(Object mount) {
    if (!identical(_activeMount, mount)) return;
    _activeMount = null;
    onPageFinished = null;
  }
}

/// Deck-scoped store of [WebViewController] instances keyed by cache identity.
///
/// Controllers are reused across remounts so returning to a slide does not
/// reload the page. A controller backs at most one live [WebViewWidget] at a
/// time — use sequential remount reuse, not concurrent multi-widget mounts.
/// Cleared when the owning deck is disposed.
class WebViewControllerCache {
  final _entries = <String, CachedWebViewEntry>{};

  int get length => _entries.length;

  bool contains(String key) => _entries.containsKey(key);

  CachedWebViewEntry? operator [](String key) => _entries[key];

  CachedWebViewEntry getOrCreate(
    String key,
    WebViewController Function() create,
  ) {
    return _entries.putIfAbsent(
      key,
      () => CachedWebViewEntry(controller: create()),
    );
  }

  void clear() {
    for (final entry in _entries.values) {
      entry.onPageFinished = null;
      entry._activeMount = null;
    }
    _entries.clear();
  }
}
