@TestOn('vm')
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playground/core/data/data_sources/security_scoped_file_access.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(SecurityScopedFileAccess.channelName);
  final calls = <MethodCall>[];

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'pickDecksDirectory' => {
              'path': '/Users/test/Documents',
              'bookmark': 'created-directory-bookmark',
            },
            'startAccessing' => {
              'path': '/Users/test/Documents',
              'bookmark': 'refreshed-directory-bookmark',
            },
            'stopAccessing' => null,
            _ => throw MissingPluginException(call.method),
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
    calls.clear();
  });

  test('selects, activates, refreshes, and releases a directory', () async {
    const access = SecurityScopedFileAccess();
    final picked = await access.pickDecksDirectory();
    final activated = await access.startAccessingDirectory(picked!);
    await access.stopAccessingDirectory(activated);

    expect(
      picked,
      const SecurityScopedDirectoryReference(
        path: '/Users/test/Documents',
        bookmark: 'created-directory-bookmark',
      ),
    );
    expect(
      activated,
      const SecurityScopedDirectoryReference(
        path: '/Users/test/Documents',
        bookmark: 'refreshed-directory-bookmark',
      ),
    );
    expect(calls.map((call) => call.method), [
      'pickDecksDirectory',
      'startAccessing',
      'stopAccessing',
    ]);
    expect(calls.map((call) => call.arguments), [
      null,
      'created-directory-bookmark',
      'refreshed-directory-bookmark',
    ]);
  });
}
