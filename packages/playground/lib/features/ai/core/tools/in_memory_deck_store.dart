import 'dart:async';

import 'package:superdeck_builder/superdeck_builder.dart';
import 'package:superdeck_core/superdeck_core.dart';

import '../../../../utils/memory_deck_loader.dart';
import 'deck_store.dart';
import 'errors.dart';

/// Reads the live slide list from the shared [DeckController].
typedef SlidesProvider = List<Slide> Function();

/// In-memory [DeckStore] — web-safe, no dart:io.
class InMemoryDeckStore implements DeckStore {
  InMemoryDeckStore({
    required SlidesProvider slidesProvider,
    required MemoryDeckLoader loader,
    Duration timeout = const Duration(seconds: 2),
    Duration pollInterval = const Duration(milliseconds: 10),
  }) : _slidesProvider = slidesProvider,
       _loader = loader,
       _timeout = timeout,
       _pollInterval = pollInterval;

  final SlidesProvider _slidesProvider;
  final MemoryDeckLoader _loader;
  final Duration _timeout;
  final Duration _pollInterval;

  @override
  Future<DeckDocument> readRequired() async {
    return DeckDocument(slides: List.unmodifiable(_slidesProvider()));
  }

  @override
  Future<void> writeCanonical(List<Slide> slides) async {
    final markdown = const SlideSerializer().serialize(slides);
    await _writeAndObserveCanonical(markdown);
  }

  @override
  Future<String> flushMarkdownToCanonical(String markdown) =>
      writeCanonicalMarkdown(markdown);

  @override
  Future<String> writeCanonicalMarkdown(String markdown) async {
    final slides = _parseMarkdown(markdown);
    final canonical = const SlideSerializer().serialize(slides);
    await _writeAndObserveCanonical(canonical);
    return canonical;
  }

  List<Slide> _parseMarkdown(String markdown) {
    try {
      final rawSlides = const MarkdownParser().parse(markdown);
      return [
        for (final raw in rawSlides)
          Slide(
            key: raw.key,
            options: SlideOptions.parse(raw.frontmatter),
            sections: const SectionParser().parse(raw.content),
            comments: const CommentParser().parse(raw.content),
          ),
      ];
    } catch (error) {
      throw DeckToolException.deckWriteFailed(
        'Could not parse markdown: $error',
      );
    }
  }

  Future<void> _writeAndObserveCanonical(String canonicalMarkdown) async {
    StreamSubscription<SlidesEvent>? subscription;
    final eventCompleter = Completer<void>();

    try {
      subscription = _loader.load().listen(
        (event) {
          if (eventCompleter.isCompleted) return;
          switch (event) {
            case SlidesLoadedEvent():
              eventCompleter.complete();
            case SlidesErrorEvent(:final message, :final error):
              eventCompleter.completeError(
                DeckToolException.deckWriteFailed(
                  error == null ? message : '$message ($error)',
                ),
              );
            case SlidesLoadingEvent() || SlidesRebuildingEvent():
              break;
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!eventCompleter.isCompleted) {
            eventCompleter.completeError(
              DeckToolException.deckWriteFailed('$error'),
              stackTrace,
            );
          }
        },
        cancelOnError: false,
      );

      _loader.updateMarkdown(canonicalMarkdown);

      await eventCompleter.future.timeout(
        _timeout,
        onTimeout: () => throw DeckToolException.deckWriteFailed(
          'Timed out waiting for loader event',
        ),
      );

      await _waitForLiveCanonical(canonicalMarkdown);
    } on DeckToolException {
      rethrow;
    } catch (error) {
      throw DeckToolException.deckWriteFailed('$error');
    } finally {
      await subscription?.cancel();
    }
  }

  Future<void> _waitForLiveCanonical(String expectedCanonical) async {
    final deadline = DateTime.now().add(_timeout);
    String? lastObserved;
    Object? lastError;

    while (DateTime.now().isBefore(deadline)) {
      try {
        final observed = const SlideSerializer().serialize(_slidesProvider());
        lastObserved = observed;
        if (observed == expectedCanonical) return;
      } catch (error) {
        lastError = error;
      }

      await Future<void>.delayed(_pollInterval);
    }

    if (lastError != null) {
      throw DeckToolException.deckWriteFailed(
        'Timed out while observing live slides: $lastError',
      );
    }

    throw DeckToolException.deckWriteFailed(
      'Timed out waiting for live canonical markdown. '
      'Last observed: ${lastObserved ?? '<none>'}',
    );
  }
}
