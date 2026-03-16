import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/deck/deck_controller.dart';
import 'package:superdeck/src/deck/deck_options.dart';
import 'package:superdeck/src/deck/slide_page_content.dart';
import 'package:superdeck/src/ui/widgets/provider.dart';
import 'package:superdeck_core/superdeck_core.dart';

final class _EmptyDeckLoader extends DeckLoader {
  final _events = StreamController<SlidesEvent>.broadcast();

  var _started = false;
  var _disposed = false;

  _EmptyDeckLoader() : super(workspace: DeckWorkspace());

  @override
  Stream<SlidesEvent> load() {
    if (_started) return _events.stream;

    _started = true;
    Future.microtask(() {
      if (_disposed) return;
      _events.add(SlidesLoadingEvent('Loading…'));
      _events.add(SlidesLoadedEvent(const <Slide>[]));
    });

    return _events.stream;
  }

  @override
  Future<void> reload() async {}

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _events.close();
  }
}

void main() {
  testWidgets('empty state is generic and does not mention builder paths', (
    tester,
  ) async {
    final loader = _EmptyDeckLoader();
    final controller = DeckController(
      deckLoader: loader,
      options: const DeckOptions(),
    );

    addTearDown(() async {
      controller.dispose();
      await loader.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: InheritedData(
          data: controller,
          child: const SlidePageContent(index: 0),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('No slides available'), findsOneWidget);
    expect(
      find.text("This presentation doesn't have any slides to show yet."),
      findsOneWidget,
    );
    expect(find.textContaining('slides.md'), findsNothing);
    expect(find.textContaining('rebuild'), findsNothing);
  });
}
