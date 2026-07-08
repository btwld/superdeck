import 'dart:async' show FutureOr;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../deck/deck_controller.dart';
import '../../deck/slide_configuration.dart';
import '../../rendering/blocks/block_provider.dart';
import 'icon_button.dart';
import 'webview_controller_cache.dart';

/// Shared persistent WebView surface for built-ins (`@webview`, `@dartpad`).
///
/// Live mounts resolve a deck-scoped cache identity (explicit [cacheKey] or the
/// block [BlockConfiguration.runtimeKey]) and reuse the controller across
/// remounts. [loadRequest] runs only on first create or URL change.
///
/// [cacheKey] is for sequential reuse (leave a slide, return later), not for
/// mounting the same controller in two widgets at once.
///
/// When [SlideConfiguration.isStaticRendering] is true, renders a placeholder
/// and never creates a controller.
class WebViewWrapper extends StatefulWidget {
  final String url;
  final Size size;
  final String? cacheKey;
  final String? title;
  final List<String>? allowedHosts;
  final bool showControls;
  final bool javascript;
  final bool showClearControl;

  const WebViewWrapper({
    super.key,
    required this.url,
    required this.size,
    this.cacheKey,
    this.title,
    this.allowedHosts,
    this.showControls = false,
    this.javascript = true,
    this.showClearControl = false,
  });

  @override
  State<WebViewWrapper> createState() => _WebViewWrapperState();
}

class _WebViewWrapperState extends State<WebViewWrapper> {
  final _mountToken = Object();

  WebViewController? _controller;
  CachedWebViewEntry? _cachedEntry;
  WebViewNavigationPolicy? _localPolicy;
  bool _hide = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindController(previousUrl: widget.url);
  }

  @override
  void didUpdateWidget(WebViewWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    final propsChanged =
        oldWidget.url != widget.url ||
        oldWidget.cacheKey != widget.cacheKey ||
        oldWidget.javascript != widget.javascript ||
        !listEquals(oldWidget.allowedHosts, widget.allowedHosts);
    if (!propsChanged) return;
    _bindController(previousUrl: oldWidget.url);
  }

  @override
  void dispose() {
    _releaseCachedEntry();
    super.dispose();
  }

  bool get _isStaticRendering {
    return SlideConfiguration.of(context).isStaticRendering;
  }

  String _resolveCacheIdentity() {
    final explicit = widget.cacheKey?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return 'key:$explicit';
    }
    return 'block:${BlockConfiguration.of(context).runtimeKey}';
  }

  Set<String> _effectiveAllowedHosts(String url) {
    final explicit = widget.allowedHosts;
    if (explicit != null && explicit.isNotEmpty) {
      return explicit.toSet();
    }
    final host = Uri.tryParse(url)?.host;
    if (host == null || host.isEmpty) return {};
    return {host};
  }

  JavaScriptMode get _javaScriptMode =>
      widget.javascript ? JavaScriptMode.unrestricted : JavaScriptMode.disabled;

  void _bindController({String? previousUrl}) {
    if (_isStaticRendering) {
      _releaseCachedEntry();
      _controller = null;
      _localPolicy = null;
      return;
    }

    final identity = _resolveCacheIdentity();
    final cache = DeckController.of(context).webViewControllerCache;
    final hosts = _effectiveAllowedHosts(widget.url);

    _localPolicy = null;
    _attachCached(cache, identity, hosts, previousUrl: previousUrl);
  }

  void _releaseCachedEntry({CachedWebViewEntry? entry}) {
    final entryToRelease = entry ?? _cachedEntry;
    entryToRelease?.release(_mountToken);
    if (identical(_cachedEntry, entryToRelease)) {
      _cachedEntry = null;
    }
  }

  void _attachCached(
    WebViewControllerCache cache,
    String identity,
    Set<String> hosts, {
    String? previousUrl,
  }) {
    final previousEntry = _cachedEntry;
    final isNew = !cache.contains(identity);
    final entry = cache.getOrCreate(identity, () {
      return _createController(
        onPageFinished: () => cache[identity]?.onPageFinished?.call(),
        onNavigationRequest: (request) {
          return cache[identity]?.policy.decide(request) ??
              NavigationDecision.prevent;
        },
      );
    });

    final switchedEntry =
        previousEntry != null && !identical(previousEntry, entry);
    if (switchedEntry) {
      _releaseCachedEntry(entry: previousEntry);
    }

    if (!entry.activate(_mountToken)) {
      _cachedEntry = null;
      _controller = null;
      _localPolicy = null;
      _attachLocal(hosts, previousUrl: previousUrl);
      return;
    }

    entry.policy.allowedHosts = hosts;
    entry.onPageFinished = _onPageFinished;
    entry.controller.setJavaScriptMode(_javaScriptMode);

    final alreadyLoaded = entry.loadedUrl == widget.url;
    if (isNew || !alreadyLoaded) {
      _hide = true;
      entry.loadedUrl = widget.url;
      entry.controller.loadRequest(Uri.parse(widget.url));
    } else if (switchedEntry || _controller == null) {
      // Already warm — remount or entry switch will not fire page-finished.
      _hide = false;
    }

    _cachedEntry = entry;
    _controller = entry.controller;
  }

  void _attachLocal(Set<String> hosts, {String? previousUrl}) {
    _cachedEntry = null;
    final policy = _localPolicy ??= WebViewNavigationPolicy();
    policy.allowedHosts = hosts;

    if (_controller == null) {
      _controller = _createController(
        onPageFinished: _onPageFinished,
        onNavigationRequest: policy.decide,
      );
      _hide = true;
      _controller!.loadRequest(Uri.parse(widget.url));
      return;
    }

    // Prop-only updates: always refresh JS mode; policy object is shared with
    // the existing navigation delegate so host changes apply in place.
    _controller!.setJavaScriptMode(_javaScriptMode);

    if (previousUrl != widget.url) {
      _hide = true;
      _controller!.loadRequest(Uri.parse(widget.url));
    }
  }

  WebViewController _createController({
    required VoidCallback onPageFinished,
    required FutureOr<NavigationDecision> Function(NavigationRequest)
    onNavigationRequest,
  }) {
    return WebViewController()
      ..setJavaScriptMode(_javaScriptMode)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => onPageFinished(),
          onNavigationRequest: onNavigationRequest,
        ),
      );
  }

  void _onPageFinished() {
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _hide = false);
    });
  }

  Future<void> _reload() async {
    final controller = _controller;
    if (controller == null) return;
    setState(() => _hide = true);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    await controller.reload();
  }

  Future<void> _clearDartPadEditor() {
    final controller = _controller;
    if (controller == null) return Future<void>.value();
    return controller.runJavaScript('''
                var editor = document.querySelector('.CodeMirror')?.CodeMirror;
                if (editor) {
                  editor.setValue('');
                  editor.setCursor({line: 0, ch: 0});
                  editor.focus();
                  console.log('DartPad editor cleared!');
                }
            ''');
  }

  Widget _buildPlaceholder() {
    final title = widget.title?.trim();
    final label = (title != null && title.isNotEmpty)
        ? title
        : 'WebView unavailable in static capture';
    return SizedBox(
      width: widget.size.width,
      height: widget.size.height,
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isStaticRendering) return _buildPlaceholder();

    final controller = _controller;
    if (controller == null) {
      return SizedBox(width: widget.size.width, height: widget.size.height);
    }

    final showToolbar = widget.showControls || widget.showClearControl;

    return SizedBox(
      width: widget.size.width,
      height: widget.size.height,
      child: Stack(
        children: [
          AnimatedOpacity(
            opacity: _hide ? 0 : 1,
            duration: const Duration(milliseconds: 150),
            child: WebViewWidget(controller: controller),
          ),
          if (showToolbar)
            Row(
              children: [
                if (widget.showControls)
                  SDIconButton(onPressed: _reload, icon: Icons.refresh),
                if (widget.showClearControl)
                  SDIconButton(
                    onPressed: _clearDartPadEditor,
                    icon: Icons.clear,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
