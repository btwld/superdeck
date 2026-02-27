import 'dart:convert' show jsonEncode;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:superdeck/src/ui/widgets/icon_button.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewWrapper extends StatefulWidget {
  final String url;
  final Size size;

  const WebViewWrapper({super.key, required this.url, required this.size});

  @override
  State<WebViewWrapper> createState() => _WebViewWrapperState();
}

class _WebViewWrapperState extends State<WebViewWrapper>
    with AutomaticKeepAliveClientMixin {
  late WebViewController _controller;
  bool _hide = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _showDartPad();
          },
          onNavigationRequest: (NavigationRequest request) {
            final sourceHost = Uri.tryParse(widget.url)?.host;
            if (sourceHost == null) {
              debugPrint(
                'WebViewWrapper: unable to parse host from "${widget.url}". '
                'Blocking navigation to "${request.url}".',
              );
            }
            final requestHost = Uri.tryParse(request.url)?.host;
            if (sourceHost != null && requestHost == sourceHost) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      );

    _loadDartPad();
  }

  @override
  void didUpdateWidget(WebViewWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      setState(() {
        _hide = true;
      });
      _loadDartPad();
    }
  }

  Future<void> _loadDartPad() async {
    await _controller.loadRequest(Uri.parse(widget.url));
  }

  Future<void> _showDartPad() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _hide = false;
    });
  }

  Future<void> _reloadDartPad() async {
    setState(() {
      _hide = true;
    });
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    await _controller.reload();
  }

  Future<void> executeInIframe(String code) {
    return _controller.runJavaScript(code);
  }

  Future<void> clearDartPadEditor() {
    return executeInIframe('''
                var editor = document.querySelector('.CodeMirror')?.CodeMirror;
                if (editor) {
                  editor.setValue('');
                  editor.setCursor({line: 0, ch: 0});
                  editor.focus();
                  console.log('DartPad editor cleared!');
                }
            ''');
  }

  // Function to set content in the DartPad editor
  Future<void> setDartPadEditorContent(String content) {
    // Escape content as JSON string to prevent JavaScript injection
    final escapedContent = jsonEncode(content);
    return executeInIframe('''
                var editor = document.querySelector('.CodeMirror')?.CodeMirror;
                if(editor){
                  editor.setValue($escapedContent);
                  editor.setCursor(editor.lineCount(), 0);
                  editor.focus();
                  console.log('DartPad editor content set!');
                }
            ''');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SizedBox(
      width: widget.size.width,
      height: widget.size.height,
      child: Stack(
        children: [
          AnimatedOpacity(
            opacity: _hide ? 0 : 1,
            duration: const Duration(milliseconds: 150),
            child: WebViewWidget(controller: _controller),
          ),
          Row(
            children: [
              SDIconButton(onPressed: _reloadDartPad, icon: Icons.refresh),
              // add button that clears the webview by running javascript
              SDIconButton(onPressed: clearDartPadEditor, icon: Icons.clear),
            ],
          ),
        ],
      ),
    );
  }
}
