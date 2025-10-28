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
    // (widget._uniqueKey).currentState?.dispose();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            _showDartPad();
          },
          onHttpError: (HttpResponseError error) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      );

    _loadDartPad();
  }

  Future<void> _loadDartPad() async {
    await _controller.loadRequest(Uri.parse(widget.url));
  }

  Future<void> _showDartPad() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _hide = false;
    });
  }

  Future<void> _reloadDartPad() async {
    setState(() {
      _hide = true;
    });
    await Future.delayed(const Duration(milliseconds: 150));
    await _controller.reload();
  }

  Future<void> executeInIframe(String code) {
    return _controller.runJavaScript(code);
  }

  Future<void> clearDartPadEditor() {
    _controller.reload();
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
    return executeInIframe('''
                var editor = document.querySelector('.CodeMirror')?.CodeMirror;
                if(editor){
                  editor.setValue($content);
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
