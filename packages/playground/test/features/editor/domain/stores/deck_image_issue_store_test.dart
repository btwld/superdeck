import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:playground/core/domain/generated_image_asset.dart';
import 'package:playground/features/ai/image_generation/image_generator.dart';
import 'package:playground/features/editor/domain/files/deck_file.dart';
import 'package:playground/features/editor/domain/files/deck_image_manifest.dart';
import 'package:playground/features/editor/domain/stores/deck_asset_cache_store.dart';
import 'package:playground/features/editor/domain/stores/deck_document_store.dart';
import 'package:playground/features/editor/domain/stores/deck_file_session.dart';
import 'package:playground/features/editor/domain/stores/deck_image_issue_store.dart';

import '../../../../helpers/fake_deck_file_repository.dart';

final class _FakeImageGenerator implements ImageGenerator {
  ImageGenerationResult result = ImageGenerationSuccess(
    Uint8List.fromList([7, 8, 9]),
  );
  Object? error;
  final List<ImageGenerationRequest> requests = [];

  @override
  Future<ImageGenerationResult> generate(ImageGenerationRequest request) async {
    requests.add(request);
    if (error case final error?) throw error;
    return result;
  }
}

void main() {
  const reference = DeckFileReference(path: '/decks/retry.md');
  const failed = GeneratedImageAsset.failure(
    assetKey: 'slide-01-risk-illustration.png',
    slideKey: 'risk',
    subject: 'a fragile bridge',
    prompt: 'paint a fragile bridge',
    aspectRatio: GeneratedImageAspectRatio.slide3x4,
    error: 'Provider unavailable',
  );

  late FakeDeckFileRepository repository;
  late DeckDocumentStore documentStore;
  late DeckAssetCacheStore assetStore;
  late DeckFileSession fileSession;
  late _FakeImageGenerator imageGenerator;
  late DeckImageIssueStore issueStore;

  setUp(() async {
    repository = FakeDeckFileRepository()
      ..files[reference.path] = '# Retry'
      ..imageManifests[deckAssetsDirectoryPath(reference.path)] =
          DeckImageManifest.fromAssets([failed]);
    documentStore = DeckDocumentStore(markdown: '# Retry');
    assetStore = DeckAssetCacheStore();
    fileSession = DeckFileSession(
      initialSnapshot: const DeckFileSnapshot(
        reference: reference,
        markdown: '# Retry',
      ),
      repository: repository,
      documentStore: documentStore,
      assetCacheStore: assetStore,
    );
    imageGenerator = _FakeImageGenerator();
    issueStore = DeckImageIssueStore(
      fileSession: fileSession,
      repository: repository,
      imageGenerator: imageGenerator,
      assetCacheStore: assetStore,
    );
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() {
    issueStore.dispose();
    fileSession.dispose();
    documentStore.dispose();
    assetStore.dispose();
  });

  test('successful retry fills the same key and clears the issue', () async {
    var refreshes = 0;
    assetStore.addListener(() => refreshes++);

    await issueStore.retry(issueStore.issues.single);

    expect(issueStore.issues, isEmpty);
    expect(imageGenerator.requests.single.prompt, failed.prompt);
    expect(imageGenerator.requests.single.aspectRatio, failed.aspectRatio);
    expect(
      repository.assets[p.join(
        deckAssetsDirectoryPath(reference.path),
        failed.assetKey,
      )],
      [7, 8, 9],
    );
    expect(refreshes, 1);
  });

  test('failed manual retry remains visible with its latest error', () async {
    imageGenerator.result = const ImageGenerationFailure('Quota exhausted.');

    await issueStore.retry(issueStore.issues.single);

    expect(issueStore.issues, hasLength(1));
    expect(issueStore.issues.single.error, 'Quota exhausted.');
    expect(issueStore.isRetrying(failed.assetKey), isFalse);
  });

  test('provider exceptions become safe persistent failures', () async {
    imageGenerator.error = StateError('provider-internal-secret');

    await issueStore.retry(issueStore.issues.single);

    expect(issueStore.issues, hasLength(1));
    expect(
      issueStore.issues.single.error,
      'Sorry, something went wrong. Please try again.',
    );
    expect(
      issueStore.issues.single.error,
      isNot(contains('provider-internal-secret')),
    );
    expect(issueStore.isRetrying(failed.assetKey), isFalse);
  });
}
