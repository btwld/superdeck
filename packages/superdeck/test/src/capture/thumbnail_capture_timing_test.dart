import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/superdeck.dart';
import 'package:superdeck_core/superdeck_core.dart';

class _InMemoryCacheStore implements AssetCacheStore {
  final Map<String, List<int>> _store = {};

  @override
  Future<Uri?> resolve(String assetKey) async {
    final bytes = _store[assetKey];
    if (bytes == null) return null;
    return Uri.parse('memory://$assetKey');
  }

  @override
  Future<Uri?> write(String assetKey, List<int> bytes) async {
    _store[assetKey] = bytes;
    return Uri.parse('memory://$assetKey');
  }

  @override
  Future<void> delete(String assetKey) async {
    _store.remove(assetKey);
  }
}

WidgetFactory _delayedWidgetFactory({
  required Duration delay,
  required Completer<void> settled,
}) {
  return (_) => _DelayedWidget(delay: delay, settled: settled);
}

class _DelayedWidget extends StatefulWidget {
  final Duration delay;
  final Completer<void> settled;

  const _DelayedWidget({required this.delay, required this.settled});

  @override
  State<_DelayedWidget> createState() => _DelayedWidgetState();
}

class _DelayedWidgetState extends State<_DelayedWidget> {
  SlideCaptureReadinessHandle? _readiness;
  var _isReady = false;
  late final Future<void> _future = Future<void>.delayed(widget.delay).then((
    _,
  ) {
    _isReady = true;
    _readiness?.complete();
    if (!widget.settled.isCompleted) {
      widget.settled.complete();
    }
  });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isReady && _readiness == null) {
      _readiness = SlideCaptureReadiness.track(
        context,
        label: 'delayed-test-widget',
      );
    }
  }

  @override
  void dispose() {
    _readiness?.complete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snapshot) {
        return Center(
          child: Text(
            snapshot.connectionState == ConnectionState.done
                ? 'Delayed widget settled'
                : 'Waiting for delayed widget',
          ),
        );
      },
    );
  }
}

class _NeverReadyWidget extends StatefulWidget {
  const _NeverReadyWidget();

  @override
  State<_NeverReadyWidget> createState() => _NeverReadyWidgetState();
}

class _NeverReadyWidgetState extends State<_NeverReadyWidget> {
  SlideCaptureReadinessHandle? _readiness;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _readiness ??= SlideCaptureReadiness.track(
      context,
      label: 'never-ready-test-widget',
    );
  }

  @override
  void dispose() {
    _readiness?.complete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

SlideConfiguration _slide(String key, String content) {
  return SlideConfiguration(
    slideIndex: 0,
    style: SlideStyler(),
    slide: Slide(
      key: key,
      sections: [
        SectionBlock([ContentBlock(content)]),
      ],
    ),
    thumbnailKey: 'thumbnail_$key.png',
  );
}

SlideConfiguration _slideWithParts(String key, String content) {
  return SlideConfiguration(
    slideIndex: 0,
    style: SlideStyler(),
    parts: const SlideParts(),
    slide: Slide(
      key: key,
      sections: [
        SectionBlock([ContentBlock(content)]),
      ],
    ),
    thumbnailKey: 'thumbnail_$key.png',
  );
}

SlideConfiguration _delayedSlide({
  required Duration delay,
  required Completer<void> settled,
  String widgetName = 'delayed',
}) {
  return SlideConfiguration(
    slideIndex: 0,
    style: SlideStyler(),
    slide: Slide(
      key: 'delayed',
      sections: [
        SectionBlock([WidgetBlock(name: widgetName, args: const {})]),
      ],
    ),
    widgets: {
      widgetName: _delayedWidgetFactory(delay: delay, settled: settled),
    },
    thumbnailKey: 'thumbnail_delayed.png',
  );
}

SlideConfiguration _neverReadySlide() {
  return SlideConfiguration(
    slideIndex: 0,
    style: SlideStyler(),
    slide: Slide(
      key: 'never-ready',
      sections: [
        SectionBlock([WidgetBlock(name: 'never-ready', args: const {})]),
      ],
    ),
    widgets: {'never-ready': (_) => const _NeverReadyWidget()},
    thumbnailKey: 'thumbnail_never_ready.png',
  );
}

Future<BuildContext> _pumpContext(WidgetTester tester) async {
  final key = GlobalKey();
  await tester.pumpWidget(MaterialApp(home: SizedBox(key: key)));
  return key.currentContext!;
}

void main() {
  group('Thumbnail capture timing', () {
    testWidgets('waits for delayed widget content before capture completes', (
      tester,
    ) async {
      final context = await _pumpContext(tester);
      final settled = Completer<void>();
      final slide = _delayedSlide(
        delay: const Duration(milliseconds: 40),
        settled: settled,
      );

      await tester.runAsync(() async {
        final stopwatch = Stopwatch()..start();
        final bytes = await SlideCaptureService().capture(
          slide: slide,
          context: context,
        );
        stopwatch.stop();

        expect(bytes, isNotEmpty);
        expect(settled.isCompleted, isTrue);
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(40));
      });
    });

    testWidgets('captures slides with chrome parts', (tester) async {
      final context = await _pumpContext(tester);
      final slide = _slideWithParts(
        'parts',
        '# Slide with parts\n\nHeader and footer stay inside capture bounds.',
      );

      await tester.runAsync(() async {
        final bytes = await SlideCaptureService().capture(
          slide: slide,
          context: context,
        );

        expect(bytes, isNotEmpty);
      });
    });

    testWidgets('only includes debug layout guides when requested', (
      tester,
    ) async {
      final context = await _pumpContext(tester);
      final slide = _slide('debug-layout', '# Layout guides');
      final capture = SlideCaptureService();

      await tester.runAsync(() async {
        final cleanBytes = await capture.capture(
          quality: SlideCaptureQuality.good,
          slide: slide,
          context: context,
        );
        final debugBytes = await capture.capture(
          quality: SlideCaptureQuality.good,
          slide: slide,
          context: context,
          includeDebugLayout: true,
        );

        expect(cleanBytes, isNot(equals(debugBytes)));
      });
    });

    testWidgets('waits longer for asynchronous image widget content', (
      tester,
    ) async {
      final context = await _pumpContext(tester);
      final settled = Completer<void>();
      final slide = _delayedSlide(
        delay: const Duration(milliseconds: 400),
        settled: settled,
        widgetName: 'image',
      );

      await tester.runAsync(() async {
        final bytes = await SlideCaptureService().capture(
          slide: slide,
          context: context,
        );

        expect(bytes, isNotEmpty);
        expect(settled.isCompleted, isTrue);
      });
    });

    testWidgets('does not impose a fixed delay on an already-ready image', (
      tester,
    ) async {
      final context = await _pumpContext(tester);
      final settled = Completer<void>();
      final slide = _delayedSlide(
        delay: Duration.zero,
        settled: settled,
        widgetName: 'image',
      );

      await tester.runAsync(() async {
        final stopwatch = Stopwatch()..start();
        final bytes = await SlideCaptureService().capture(
          slide: slide,
          context: context,
        );
        stopwatch.stop();

        expect(bytes, isNotEmpty);
        expect(settled.isCompleted, isTrue);
        expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 350)));
      });
    });

    testWidgets('bounds capture when registered readiness never completes', (
      tester,
    ) async {
      final context = await _pumpContext(tester);

      await tester.runAsync(() async {
        final stopwatch = Stopwatch()..start();
        final bytes = await SlideCaptureService().capture(
          slide: _neverReadySlide(),
          context: context,
        );
        stopwatch.stop();

        expect(bytes, isNotEmpty);
        expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
      });
    });

    testWidgets('measures real capture and cache times', (tester) async {
      final context = await _pumpContext(tester);
      final cacheStore = _InMemoryCacheStore();
      final service = ThumbnailService(
        cacheStore: cacheStore,
        slideCaptureService: SlideCaptureService(),
      );

      final slides = [
        _slide('s0', '# Hello World\n\nThis is slide one.'),
        _slide('s1', '## Second Slide\n\n- Item A\n- Item B\n- Item C'),
        _slide('s2', '### Third Slide\n\nSome **bold** and *italic* text.'),
      ];

      // Use tester.runAsync to allow real Future.delayed calls
      // inside SlideCaptureService's render pipeline
      await tester.runAsync(() async {
        // Generation (cache miss → real capture + write)
        final genTimes = <int>[];
        for (final slide in slides) {
          final sw = Stopwatch()..start();
          await service.generateThumbnail(
            slide: slide,
            context: context,
            force: false,
          );
          sw.stop();
          genTimes.add(sw.elapsedMilliseconds);
        }

        // Cache hit (resolve from in-memory map)
        final hitTimes = <int>[];
        for (final slide in slides) {
          final sw = Stopwatch()..start();
          await service.generateThumbnail(
            slide: slide,
            context: context,
            force: false,
          );
          sw.stop();
          hitTimes.add(sw.elapsedMilliseconds);
        }

        // Force regeneration (delete + capture + write)
        final forceTimes = <int>[];
        for (final slide in slides) {
          final sw = Stopwatch()..start();
          await service.generateThumbnail(
            slide: slide,
            context: context,
            force: true,
          );
          sw.stop();
          forceTimes.add(sw.elapsedMilliseconds);
        }

        final genTotal = genTimes.reduce((a, b) => a + b);
        final hitTotal = hitTimes.reduce((a, b) => a + b);
        final forceTotal = forceTimes.reduce((a, b) => a + b);

        // ignore: avoid_print
        print('\n=== Thumbnail Capture Timing (${slides.length} slides) ===');
        for (var i = 0; i < slides.length; i++) {
          // ignore: avoid_print
          print(
            'Slide $i: generate=${genTimes[i]}ms  '
            'cache-hit=${hitTimes[i]}ms  '
            'force=${forceTimes[i]}ms',
          );
        }
        // ignore: avoid_print
        print('---');
        // ignore: avoid_print
        print(
          'Total: generate=${genTotal}ms  '
          'cache-hit=${hitTotal}ms  '
          'force=${forceTotal}ms',
        );
        // ignore: avoid_print
        print('================================================\n');

        expect(hitTotal, lessThan(genTotal));
      });
    });

    testWidgets('measures concurrent batch generation (20 slides)', (
      tester,
    ) async {
      final context = await _pumpContext(tester);
      final cacheStore = _InMemoryCacheStore();
      final service = ThumbnailService(
        cacheStore: cacheStore,
        slideCaptureService: SlideCaptureService(),
      );

      final slides = List.generate(
        20,
        (i) => _slide('batch-$i', '# Slide $i\n\nContent for slide number $i.'),
      );

      await tester.runAsync(() async {
        // Concurrent generation — all fire at once, like the real app
        final batchSw = Stopwatch()..start();
        await Future.wait([
          for (final slide in slides)
            service.generateThumbnail(
              slide: slide,
              context: context,
              force: false,
            ),
        ]);
        batchSw.stop();
        final batchMs = batchSw.elapsedMilliseconds;

        // Cache hits for all 20
        final hitSw = Stopwatch()..start();
        await Future.wait([
          for (final slide in slides)
            service.generateThumbnail(
              slide: slide,
              context: context,
              force: false,
            ),
        ]);
        hitSw.stop();
        final hitMs = hitSw.elapsedMilliseconds;

        // Force regen all 20 concurrently
        final forceSw = Stopwatch()..start();
        await Future.wait([
          for (final slide in slides)
            service.generateThumbnail(
              slide: slide,
              context: context,
              force: true,
            ),
        ]);
        forceSw.stop();
        final forceMs = forceSw.elapsedMilliseconds;

        // ignore: avoid_print
        print('\n=== Concurrent Batch Timing (${slides.length} slides) ===');
        // ignore: avoid_print
        print(
          'Generate all: ${batchMs}ms  (${(batchMs / slides.length).toStringAsFixed(0)}ms/slide wall-clock)',
        );
        // ignore: avoid_print
        print('Cache hit all: ${hitMs}ms');
        // ignore: avoid_print
        print(
          'Force regen all: ${forceMs}ms  (${(forceMs / slides.length).toStringAsFixed(0)}ms/slide wall-clock)',
        );
        // ignore: avoid_print
        print('=============================================\n');

        expect(hitMs, lessThan(batchMs));
      });
    });
  });
}
