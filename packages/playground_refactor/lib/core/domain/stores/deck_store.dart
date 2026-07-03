import 'package:flutter/foundation.dart';
import 'package:superdeck/superdeck.dart';

/// Bridges [DeckController.slides] (a signal) to a plain [ChangeNotifier].
///
/// This is the single read-surface for the deck's slides in the new package —
/// the presentation layer consumes it via `context.watch`/`context.select` and
/// never touches signals. Signal usage is confined to this bridge.
class DeckStore extends ChangeNotifier {
  DeckStore(this._controller) {
    _slides = _controller.slides.value;
    _cancel = _controller.slides.subscribe((value) {
      _slides = value;
      notifyListeners();
    });
  }

  final DeckController _controller;

  late List<SlideConfiguration> _slides;
  late final void Function() _cancel;

  List<SlideConfiguration> get slides => _slides;

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }
}
