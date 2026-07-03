import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:signals/signals.dart';
import 'package:superdeck/superdeck.dart';

import '../../../../core/domain/stores/deck_customization_store.dart';
import '../../../../core/domain/stores/deck_store.dart';
import 'editor_store.dart';

/// Owns both halves of the preview thumbnails: the read projection consumed by
/// the sidebar *and* the policy that decides when to regenerate.
///
/// Read side — a single [effect] bridges every current thumbnail's `status`
/// signal into a plain map; the sidebar reads [statusFor] / [thumbnailFor] via
/// `context.select` and never touches signals.
///
/// Write side — listens to [DeckStore], [EditorStore], and
/// [DeckCustomizationStore] and requests a regeneration when: the deck first
/// loads, the active slide changes (the slide just left has settled), or a
/// deck-wide style change lands (debounced, and every cached thumbnail is wiped
/// first because content-hash keys don't change on a restyle).
///
/// The capture itself needs a live [BuildContext] and a laid-out frame, which a
/// store cannot own — so [reloadRequests] fires when a regeneration is due and
/// the preview list calls [reload] with its own context inside a post-frame
/// callback.
class ThumbnailStore extends ChangeNotifier {
  ThumbnailStore({
    required DeckController controller,
    required DeckStore deckStore,
    required EditorStore editorStore,
    required DeckCustomizationStore customization,
  }) : _controller = controller,
       _deckStore = deckStore,
       _editorStore = editorStore,
       _customization = customization {
    _statusCleanup = effect(_recompute);
    _lastActiveSlide = editorStore.activeSlideIndex;
    _deckStore.addListener(_onSlidesChanged);
    _editorStore.addListener(_onEditorChanged);
    _customization.addListener(_onStyleChanged);
    _onSlidesChanged();
  }

  static const _styleRefreshDebounce = Duration(milliseconds: 250);

  final DeckController _controller;
  final DeckStore _deckStore;
  final EditorStore _editorStore;
  final DeckCustomizationStore _customization;

  Map<String, AsyncFileStatus> _statuses = const {};
  late final void Function() _statusCleanup;

  bool _initialDone = false;
  bool _deleteFirstPending = false;
  int _lastActiveSlide = 0;
  Timer? _styleDebounce;
  final _reloadRequests = ValueNotifier<int>(0);

  /// Ticks whenever the policy decides a regeneration is due. The preview list
  /// listens to this and calls [reload] with its context on the next frame.
  Listenable get reloadRequests => _reloadRequests;

  /// The current status for [slideKey], or [AsyncFileStatus.idle] if no
  /// thumbnail has been generated yet.
  AsyncFileStatus statusFor(String slideKey) =>
      _statuses[slideKey] ?? AsyncFileStatus.idle;

  /// The live [AsyncThumbnail] for [slideKey], or null before generation.
  AsyncThumbnail? thumbnailFor(String slideKey) =>
      _controller.presentation.getThumbnail(slideKey);

  /// Regenerates thumbnails against [context]. Called by the preview list inside
  /// a post-frame callback so the capture subtree is laid out. Deletes every
  /// cached thumbnail first when a style change queued it.
  Future<void> reload(BuildContext context) async {
    final deleteFirst = _deleteFirstPending;
    _deleteFirstPending = false;
    if (deleteFirst) {
      await _controller.presentation.deleteAllThumbnails();
      if (!context.mounted) return;
    }
    _controller.presentation.generateThumbnails(context, _deckStore.slides);
  }

  void _requestReload({bool deleteFirst = false}) {
    if (deleteFirst) _deleteFirstPending = true;
    _reloadRequests.value++;
  }

  void _onSlidesChanged() {
    if (_deckStore.slides.isEmpty || _initialDone) return;
    _initialDone = true;
    _requestReload();
  }

  /// [EditorStore] notifies on text edits too; only an actual active-slide
  /// change should refresh thumbnails.
  void _onEditorChanged() {
    if (!_initialDone) return;
    final index = _editorStore.activeSlideIndex;
    if (index == _lastActiveSlide) return;
    _lastActiveSlide = index;
    _requestReload();
  }

  void _onStyleChanged() {
    if (!_initialDone) return;
    _styleDebounce?.cancel();
    _styleDebounce = Timer(
      _styleRefreshDebounce,
      () => _requestReload(deleteFirst: true),
    );
  }

  void _recompute() {
    final slides = _controller.slides.value;
    final next = <String, AsyncFileStatus>{};
    for (final slide in slides) {
      final thumbnail = _controller.presentation.getThumbnail(slide.key);
      next[slide.key] = thumbnail?.status.value ?? AsyncFileStatus.idle;
    }
    if (_sameStatuses(_statuses, next)) return;
    _statuses = next;
    notifyListeners();
  }

  bool _sameStatuses(
    Map<String, AsyncFileStatus> a,
    Map<String, AsyncFileStatus> b,
  ) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _deckStore.removeListener(_onSlidesChanged);
    _editorStore.removeListener(_onEditorChanged);
    _customization.removeListener(_onStyleChanged);
    _styleDebounce?.cancel();
    _statusCleanup();
    _reloadRequests.dispose();
    super.dispose();
  }
}
