import 'package:flutter/widgets.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../ui/widgets/webview_wrapper.dart';

/// Strongly-typed data transfer object for the webview widget.
class WebViewDto {
  final String url;
  final String? cacheKey;
  final String? title;
  final List<String>? allowedHosts;
  final bool showControls;
  final bool javascript;

  const WebViewDto({
    required this.url,
    this.cacheKey,
    this.title,
    this.allowedHosts,
    this.showControls = false,
    this.javascript = true,
  });

  /// Schema for validating webview arguments.
  static final schema = Ack.object({
    'url': Ack.string().notEmpty(),
    'cacheKey': Ack.string().nullable().optional(),
    'title': Ack.string().nullable().optional(),
    'allowedHosts': Ack.list(Ack.string()).nullable().optional(),
    'showControls': Ack.boolean().nullable().optional(),
    'javascript': Ack.boolean().nullable().optional(),
  });

  /// Parses and validates raw map into typed [WebViewDto].
  static WebViewDto parse(Map<String, Object?> map) {
    schema.parse(map);

    final rawUrl = map['url'];
    if (rawUrl is! String) {
      throw const FormatException('WebView widget requires a string "url".');
    }
    final url = rawUrl.trim();
    _validateAbsoluteHttpUrl(url);

    final rawHosts = map['allowedHosts'];
    List<String>? allowedHosts;
    if (rawHosts is List) {
      allowedHosts = rawHosts.map((host) => host.toString()).toList();
    }

    return WebViewDto(
      url: url,
      cacheKey: map['cacheKey'] as String?,
      title: map['title'] as String?,
      allowedHosts: allowedHosts,
      showControls: map['showControls'] as bool? ?? false,
      javascript: map['javascript'] as bool? ?? true,
    );
  }

  static void _validateAbsoluteHttpUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      throw FormatException(
        'WebView "url" must be an absolute http or https URL, got: "$url".',
      );
    }
  }
}

/// Built-in widget for embedding a persistent web page in slides.
///
/// Usage in markdown:
/// ```markdown
/// @webview {
///   url: https://example.com
///   title: Example
///   showControls: true
/// }
/// ```
///
/// Parameters:
/// - `url` (required): Absolute `http`/`https` URL
/// - `cacheKey` (optional): Sequential controller reuse across remounts
/// - `title` (optional): Label shown during static/thumbnail capture
/// - `allowedHosts` (optional): Navigation allowlist (default: source host)
/// - `showControls` (optional): Show refresh control (default: false)
/// - `javascript` (optional): Enable JavaScript (default: true)
class WebViewWidget extends StatelessWidget {
  final WebViewDto _data;

  WebViewWidget(Map<String, Object?> args, {super.key})
    : _data = WebViewDto.parse(args);

  @override
  Widget build(BuildContext context) {
    return WebViewWrapper(
      url: _data.url,
      cacheKey: _data.cacheKey,
      title: _data.title,
      allowedHosts: _data.allowedHosts,
      showControls: _data.showControls,
      javascript: _data.javascript,
    );
  }
}
