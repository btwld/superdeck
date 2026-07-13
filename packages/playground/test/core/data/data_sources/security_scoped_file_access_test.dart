@TestOn('vm')
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playground/core/data/data_sources/security_scoped_file_access.dart';
import 'package:playground/features/editor/domain/files/deck_file.dart';

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
            'pickDeckFile' => {
              'path': '/outside/talk.md',
              'bookmark': 'created-bookmark',
            },
            'startAccessing' => {
              'path': '/moved/talk.md',
              'bookmark': 'refreshed-bookmark',
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

  test('creates, activates, refreshes, and releases a bookmark', () async {
    const access = SecurityScopedFileAccess();
    final picked = await access.pickDeckFile();
    final activated = await access.startAccessing(picked!);
    await access.stopAccessing(activated);

    expect(
      picked,
      const DeckFileReference(
        path: '/outside/talk.md',
        bookmark: 'created-bookmark',
      ),
    );
    expect(
      activated,
      const DeckFileReference(
        path: '/moved/talk.md',
        bookmark: 'refreshed-bookmark',
      ),
    );
    expect(calls.map((call) => call.method), [
      'pickDeckFile',
      'startAccessing',
      'stopAccessing',
    ]);
    expect(calls.map((call) => call.arguments), [
      null,
      'created-bookmark',
      'refreshed-bookmark',
    ]);
  });

  test('is a no-op for an app-owned file without a bookmark', () async {
    const access = SecurityScopedFileAccess();
    const deck = DeckFileReference(path: '/app-storage/talk.md');

    expect(await access.startAccessing(deck), deck);
    await access.stopAccessing(deck);

    expect(calls, isEmpty);
  });
}
