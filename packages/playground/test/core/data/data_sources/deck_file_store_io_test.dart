@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:playground/core/data/data_sources/deck_file_store.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Points `path_provider` at a temp directory so the native store's fixed
/// App Documents storage resolves under the test sandbox.
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late NativeDeckFileStore store;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('deck_file_store_test');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    store = NativeDeckFileStore();
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('decksDirectoryPath creates the SuperDeck app-storage folder', () async {
    final dir = await store.decksDirectoryPath();
    expect(dir, p.join(temp.path, 'SuperDeck'));
    expect(await Directory(dir).exists(), isTrue);
  });

  test('write then read round-trips content', () async {
    final path = p.join(temp.path, 'nested', 'deck.md');
    await store.write(path, '# Hello');
    expect(await store.exists(path), isTrue);
    expect(await store.read(path), '# Hello');
  });

  test('read throws DeckFileReadException for a missing file', () async {
    expect(
      () => store.read(p.join(temp.path, 'missing.md')),
      throwsA(isA<DeckFileReadException>()),
    );
  });

  test('createDeck writes <name>.md and returns its path', () async {
    final path = await store.createDeck('talk', content: '# Talk');
    expect(path, p.join(temp.path, 'SuperDeck', 'talk.md'));
    expect(await File(path).readAsString(), '# Talk');
  });

  test('createDeck appends .md and strips directory components', () async {
    final path = await store.createDeck('../evil/name', content: 'x');
    expect(p.basename(path), 'name.md');
    expect(p.dirname(path), p.join(temp.path, 'SuperDeck'));
  });

  test('createDeck throws on a name collision', () async {
    await store.createDeck('talk', content: 'first');
    expect(
      () => store.createDeck('talk', content: 'second'),
      throwsA(isA<DeckNameCollisionException>()),
    );
  });
}
