import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../ai/wizard/core/ui/ui.dart';
import '../domain/deck_library_controller.dart';
import '../domain/saved_deck.dart';

/// The decks already saved to the SuperDeck folder, opened for presenting.
///
/// Decks are read-only here. Opening one publishes its Markdown, artwork and
/// theme into the runtime and presents it.
class SavedDecksPage extends StatefulWidget {
  const SavedDecksPage({super.key});

  @override
  State<SavedDecksPage> createState() => _SavedDecksPageState();
}

class _SavedDecksPageState extends State<SavedDecksPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(context.read<DeckLibraryController>().refresh());
    });
  }

  Future<void> _open(SavedDeckRef ref) async {
    final controller = context.read<DeckLibraryController>();
    final opened = await controller.open(ref);
    if (!mounted || !opened) return;
    context.push('/present/0');
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DeckLibraryController>();
    final decks = controller.decks;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const .tightFor(width: 720),
            child: Padding(
              padding: const .all(32),
              child: Column(
                crossAxisAlignment: .start,
                spacing: 20,
                children: [
                  Row(
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      const SdHeadline('Saved decks'),
                      SdButton(
                        label: 'New deck',
                        onPressed: () => context.go('/'),
                        icon: LucideIcons.sparkles,
                        variant: .outline,
                      ),
                    ],
                  ),
                  if (controller.errorMessage case final message?)
                    SdCallout(text: message, icon: LucideIcons.triangleAlert),
                  if (controller.isBusy && decks.isEmpty)
                    const SdSpinner()
                  else if (decks.isEmpty)
                    const SdBody(
                      'No decks yet. Generate one with the Wizard and save it '
                      'to see it here.',
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemBuilder: (context, index) =>
                            _SavedDeckTile(ref: decks[index], onOpen: _open),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemCount: decks.length,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedDeckTile extends StatelessWidget {
  const _SavedDeckTile({required this.ref, required this.onOpen});

  final SavedDeckRef ref;
  final Future<void> Function(SavedDeckRef ref) onOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Present ${ref.name}',
      child: Container(
        padding: const .all(16),
        decoration: BoxDecoration(
          color: $surfaceSecondary.resolve(context),
          border: .all(color: $border.resolve(context)),
          borderRadius: .circular(14),
        ),
        child: Row(
          spacing: 16,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                spacing: 4,
                children: [
                  SdTitle(ref.name),
                  SdCaption(_savedAtLabel(ref.savedAt)),
                ],
              ),
            ),
            SdButton(
              label: 'Present',
              onPressed: () => unawaited(onOpen(ref)),
              icon: LucideIcons.play,
            ),
          ],
        ),
      ),
    );
  }
}

String _savedAtLabel(DateTime savedAt) {
  final local = savedAt.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return 'Saved ${local.year}-$month-$day at $hour:$minute';
}
