import 'dart:async';

import 'package:puppeteer/puppeteer.dart';

import 'disposable.dart';

/// Service for browser automation using Puppeteer
class BrowserService implements Disposable {
  Browser? _browser;
  final Map<String, dynamic> _launchOptions;

  BrowserService({Map<String, dynamic>? launchOptions})
      : _launchOptions = launchOptions ?? {};

  /// Get or create a browser instance
  Future<Browser> getBrowser() async {
    if (_browser == null) {
      _browser = await puppeteer.launch(
        headless: _launchOptions['headless'] ?? true,
        args: _launchOptions['args'] as List<String>?,
        executablePath: _launchOptions['executablePath'] as String?,
      );
    }
    return _browser!;
  }

  /// Execute an action with a new page
  Future<T> withPage<T>(Future<T> Function(Page page) action) async {
    final browser = await getBrowser();
    final page = await browser.newPage();
    try {
      return await action(page);
    } finally {
      await page.close();
    }
  }

  @override
  Future<void> dispose() async {
    if (_browser != null) {
      await _browser!.close();
      _browser = null;
    }
  }
}
