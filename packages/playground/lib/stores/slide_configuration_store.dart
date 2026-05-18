import 'package:flutter/foundation.dart';
import 'package:superdeck/superdeck.dart';

class SlideConfigurationStore extends ChangeNotifier {
  SlideConfigurationStore(DeckController controller) {
    _slides = List.unmodifiable(controller.slides.value);
    _unsubscribe = controller.slides.subscribe((value) {
      _slides = List.unmodifiable(value);
      notifyListeners();
    });
  }

  late List<SlideConfiguration> _slides;
  late final void Function() _unsubscribe;
  int _activeSlideIndex = 0;

  List<SlideConfiguration> get slides => _slides;

  int get activeSlideIndex => _activeSlideIndex;

  set activeSlideIndex(int value) {
    final index = value - 1;

    if (_activeSlideIndex == index) return;
    _activeSlideIndex = index;
    notifyListeners();
  }

  @override
  void dispose() {
    _unsubscribe.call();
    super.dispose();
  }
}
