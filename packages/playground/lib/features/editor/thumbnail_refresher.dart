import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:superdeck/superdeck.dart';

import '../../stores/editor_state.dart';

/// Signature for the action that regenerates slide thumbnails.
///
/// When [force] is true the existing cache entries are dropped and every
/// slide is re-captured, even if its content-hash key is unchanged.
typedef ThumbnailRegenerate =
    void Function(
      BuildContext context,
      List<SlideConfiguration> slides, {
      bool force,
    });

/// Signature for the action that deletes every cached thumbnail.
typedef ThumbnailDeleteAll = Future<void> Function();

/// Keeps the preview sidebar's thumbnails in sync with the deck.
///
/// Mounted in the editor subtree, it regenerates thumbnails once when the
/// deck first loads, again whenever the active slide changes, and again on
/// any deck-wide style change.
///
/// Typing inside a slide regenerates nothing — the active slide renders live
/// in the sidebar, so its thumbnail can wait until the caret leaves it. Slide
/// keys are content hashes, so [DeckController] captures only the slides
/// whose content actually changed since the last pass.
///
/// A deck-wide style change is invisible to those content-hash keys: the
/// customization store writes a fresh [DeckOptions] but every `thumbnailKey`
/// stays the same, so reusing the cache would surface stale captures. The
/// options effect therefore deletes every cached thumbnail (in-memory and
/// persistent) and then triggers a fresh regeneration pass.
class ThumbnailRefresher extends StatefulWidget {
  const ThumbnailRefresher({
    required this.child,
    this.regenerate,
    this.deleteAllThumbnails,
    super.key,
  });

  final Widget child;

  /// Overrides the regeneration action. Defaults to
  /// `DeckController.presentation.generateThumbnails`.
  @visibleForTesting
  final ThumbnailRegenerate? regenerate;

  /// Overrides the "delete every thumbnail" action. Defaults to
  /// `DeckController.presentation.deleteAllThumbnails`.
  @visibleForTesting
  final ThumbnailDeleteAll? deleteAllThumbnails;

  @override
  State<ThumbnailRefresher> createState() => _ThumbnailRefresherState();
}

class _ThumbnailRefresherState extends State<ThumbnailRefresher> {
  static const _styleRefreshDebounce = Duration(milliseconds: 250);

  late final DeckController _controller;
  late final EditorState _editorState;
  late final ThumbnailRegenerate _regenerate;
  late final ThumbnailDeleteAll _deleteAll;
  late final EffectCleanup _initialCleanup;
  late final EffectCleanup _activeSlideCleanup;
  late final EffectCleanup _optionsCleanup;

  bool _initialDone = false;
  bool _generateScheduled = false;
  bool _forcePending = false;
  bool _deleteFirstPending = false;
  Timer? _styleDebounce;

  @override
  void initState() {
    super.initState();
    _controller = context.read<DeckController>();
    _editorState = context.read<EditorState>();
    _regenerate = widget.regenerate ?? _generateViaController;
    _deleteAll = widget.deleteAllThumbnails ?? _deleteAllViaController;

    // Initial generation: fire once, as soon as the deck has slides.
    _initialCleanup = effect(() {
      final slides = _controller.slides.value;
      if (slides.isEmpty || _initialDone) return;
      _initialDone = true;
      _scheduleGenerate();
    });

    // Regeneration: the active slide changing means the slide just left has
    // settled and is no longer rendered live — refresh thumbnails then.
    _activeSlideCleanup = effect(() {
      _editorState.activeSlideIndex.value; // subscribe
      if (!_initialDone) return;
      _scheduleGenerate();
    });

    // Deck-wide style changes don't alter content-hash slide keys on their
    // own, so wipe every cached thumbnail before recapturing.
    _optionsCleanup = effect(() {
      _controller.options.value; // subscribe
      if (!_initialDone) return;
      _styleDebounce?.cancel();
      _styleDebounce = Timer(_styleRefreshDebounce, () {
        if (!mounted) return;
        _scheduleGenerate(deleteFirst: true);
      });
    });
  }

  void _generateViaController(
    BuildContext context,
    List<SlideConfiguration> slides, {
    bool force = false,
  }) {
    _controller.presentation.generateThumbnails(context, slides, force: force);
  }

  Future<void> _deleteAllViaController() {
    return _controller.presentation.deleteAllThumbnails();
  }

  /// Coalesces triggers into a single post-frame regeneration, so the capture
  /// context is laid out and overlapping triggers do not stack. Pending
  /// [force] and [deleteFirst] requests both survive the coalesce.
  void _scheduleGenerate({bool force = false, bool deleteFirst = false}) {
    if (force) _forcePending = true;
    if (deleteFirst) _deleteFirstPending = true;
    if (_generateScheduled) return;
    _generateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _generateScheduled = false;
      final shouldForce = _forcePending;
      final shouldDeleteFirst = _deleteFirstPending;
      _forcePending = false;
      _deleteFirstPending = false;
      if (!mounted) return;
      if (shouldDeleteFirst) {
        await _deleteAll();
        if (!mounted) return;
      }
      _regenerate(context, _controller.slides.value, force: shouldForce);
    });
  }

  @override
  void dispose() {
    _initialCleanup();
    _activeSlideCleanup();
    _optionsCleanup();
    _styleDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
