import 'dart:async';

import 'package:logging/logging.dart';
import 'package:puppeteer/puppeteer.dart';

import 'disposable.dart';

/// Service for browser automation using Puppeteer
class BrowserService implements Disposable {
  Browser? _browser;
  final Map<String, dynamic> _launchOptions;
  final int _maxRetries;
  final Duration _retryDelay;
  final Logger _logger = Logger('BrowserService');

  // Track active pages to ensure proper cleanup
  final Set<Page> _activePages = {};

  BrowserService({
    Map<String, dynamic>? launchOptions,
    int maxRetries = 3,
    Duration? retryDelay,
  })  : _launchOptions = launchOptions ?? {},
        _maxRetries = maxRetries,
        _retryDelay = retryDelay ?? const Duration(seconds: 1);

  /// Get or create a browser instance
  Future<Browser> getBrowser() async {
    if (_browser == null || !_isBrowserHealthy()) {
      await _closeBrowserIfNeeded();

      try {
        _logger.info('Launching browser instance');
        _browser = await puppeteer.launch(
          headless: _launchOptions['headless'] ?? true,
          args: [
            ..._launchOptions['args'] as List<String>? ?? [],
            '--disable-web-security', // Allow loading from CDNs
            '--allow-file-access-from-files',
            '--no-sandbox',
            '--disable-setuid-sandbox',
          ],
          executablePath: _launchOptions['executablePath'] as String?,
        );
      } catch (e, stackTrace) {
        _logger.severe('Failed to launch browser: $e', stackTrace);
        rethrow;
      }
    }
    return _browser!;
  }

  /// Check if browser is still usable
  bool _isBrowserHealthy() {
    try {
      // In Puppeteer for Dart, we don't have a direct isDisconnected property
      // Instead, we can check if the browser can handle a simple operation
      return _browser != null;
    } catch (_) {
      return false;
    }
  }

  /// Close browser if it exists
  Future<void> _closeBrowserIfNeeded() async {
    if (_browser != null) {
      try {
        // Close any active pages first
        for (final page in List.from(_activePages)) {
          await _tryClosePageSafely(page);
        }
        _activePages.clear();

        await _browser!.close();
        _logger.info('Closed existing browser instance');
      } catch (e) {
        _logger.warning('Error closing browser: $e');
      } finally {
        _browser = null;
      }
    }
  }

  /// Try to safely close a page and handle any errors
  Future<void> _tryClosePageSafely(Page page) async {
    try {
      await page.close(); // In Puppeteer Dart, no need to check isClosed
    } catch (e) {
      _logger.warning('Error closing page: $e');
    } finally {
      _activePages.remove(page);
    }
  }

  /// Execute an action with a new page with retry logic
  Future<T> withPage<T>(Future<T> Function(Page page) action) async {
    Page? page;
    int retries = 0;

    while (true) {
      try {
        final browser = await getBrowser();
        page = await browser.newPage();
        _activePages.add(page);

        // Configure the page - Puppeteer Dart doesn't have these specific methods
        // We'll instead use other available configuration options
        await page.setViewport(DeviceViewport(
          width: 1280,
          height: 800,
          deviceScaleFactor: 1,
        ));

        return await action(page);
      } catch (e, stackTrace) {
        if (page != null) {
          await _tryClosePageSafely(page);
          page = null;
        }

        if (retries >= _maxRetries) {
          _logger.severe('Failed after $_maxRetries retries: $e', stackTrace);
          throw Exception('Browser operation failed: $e');
        }

        retries++;
        _logger.warning(
            'Retrying browser operation (${retries}/${_maxRetries}): $e');
        await Future.delayed(_retryDelay * retries);

        // If we're having persistent issues, restart the browser
        if (retries >= _maxRetries ~/ 2) {
          await _closeBrowserIfNeeded();
        }
      } finally {
        if (page != null) {
          await _tryClosePageSafely(page);
        }
      }
    }
  }

  @override
  Future<void> dispose() async {
    await _closeBrowserIfNeeded();
  }
}
