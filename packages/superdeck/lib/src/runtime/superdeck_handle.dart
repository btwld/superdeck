import 'package:flutter/widgets.dart';
import 'package:signals/signals.dart';

import '../export/async_thumbnail.dart';
import '../export/pdf_export_screen.dart';
import '../slides/slide_configuration.dart';
import 'deck_controller.dart';
import 'navigation/navigation_events.dart';

class SuperDeckHandle {
  DeckController? _controller;

  DeckController get _attachedController {
    final controller = _controller;
    if (controller == null) {
      throw StateError(
        'SuperDeckHandle is not attached yet. '
        'Use it after SuperDeckApp has mounted.',
      );
    }
    return controller;
  }

  ReadonlySignal<List<SlideConfiguration>> get slides =>
      _attachedController.slides;
  ReadonlySignal<SlideConfiguration?> get currentSlide =>
      _attachedController.currentSlide;
  ReadonlySignal<int> get currentIndex => _attachedController.currentIndex;
  ReadonlySignal<int> get totalSlides => _attachedController.totalSlides;
  ReadonlySignal<bool> get isLoading => _attachedController.isLoading;
  ReadonlySignal<bool> get hasError => _attachedController.hasError;
  ReadonlySignal<Object?> get error => _attachedController.error;
  ReadonlySignal<bool> get isRebuilding => _attachedController.isRebuilding;
  ReadonlySignal<bool> get isMenuOpen => _attachedController.isMenuOpen;
  ReadonlySignal<bool> get isNotesOpen => _attachedController.isNotesOpen;
  ReadonlySignal<bool> get canGoNext => _attachedController.canGoNext;
  ReadonlySignal<bool> get canGoPrevious => _attachedController.canGoPrevious;

  Future<void> goToSlide(int index) => _attachedController.goToSlide(index);

  Future<void> nextSlide() => _attachedController.nextSlide();

  Future<void> previousSlide() => _attachedController.previousSlide();

  Future<void> handleNavigationEvent(NavigationEvent event) {
    return _attachedController.handleNavigationEvent(event);
  }

  Future<void> reload() => _attachedController.reloadDeck();

  void openMenu() => _attachedController.openMenu();

  void closeMenu() => _attachedController.closeMenu();

  void toggleNotes() => _attachedController.toggleNotes();

  AsyncThumbnail? getThumbnail(String slideKey) {
    return _attachedController.getThumbnail(slideKey);
  }

  void generateThumbnails(BuildContext context, {bool force = true}) {
    _attachedController.generateThumbnails(context, force: force);
  }

  void regenerateThumbnails(BuildContext context, {bool force = true}) {
    generateThumbnails(context, force: force);
  }

  void exportPdf(BuildContext context) {
    PdfExportDialogScreen.show(context);
  }

  List<Widget> buildActions(BuildContext context) {
    return _attachedController.extensions
        .expand((extension) => extension.buildActions(context))
        .toList(growable: false);
  }

  Widget? buildFloatingAction(BuildContext context) {
    for (final extension in _attachedController.extensions) {
      final action = extension.buildFloatingAction(context);
      if (action != null) {
        return action;
      }
    }
    return null;
  }

  void attach(DeckController controller) {
    _controller = controller;
  }

  void detach(DeckController controller) {
    if (identical(_controller, controller)) {
      _controller = null;
    }
  }
}
