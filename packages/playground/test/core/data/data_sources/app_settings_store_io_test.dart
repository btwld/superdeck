@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:playground/core/data/data_sources/app_settings_store.dart';
import 'package:playground/core/data/data_sources/deck_file_store.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late NativeAppSettingsStore store;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('app_settings_store_test');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    store = const NativeAppSettingsStore();
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('round-trips a path with its security-scoped bookmark', () async {
    const deck = DeckFileReference(
      path: '/outside/talk.md',
      bookmark: 'opaque-bookmark',
    );

    await store.setLastOpenedDeck(deck);

    expect(await store.lastOpenedDeck(), deck);
  });

  test('reads the legacy path-only setting without a bookmark', () async {
    final directory = Directory(p.join(temp.path, 'superdeck_playground'));
    await directory.create(recursive: true);
    await File(
      p.join(directory.path, 'settings.json'),
    ).writeAsString(jsonEncode({'lastOpenedDeckPath': '/legacy/talk.md'}));

    expect(
      await store.lastOpenedDeck(),
      const DeckFileReference(path: '/legacy/talk.md'),
    );
  });
}
