import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../ai/wizard/core/ui/ui.dart';

/// Asks for the name a generated deck is saved under.
///
/// Saving is explicit: the Wizard never writes a deck the reader did not ask
/// for, and the name is theirs to change.
class SaveDeckDialog extends StatefulWidget {
  const SaveDeckDialog({super.key, required this.initialName});

  /// Returns the chosen name, or `null` when the reader cancelled.
  static Future<String?> show(BuildContext context, {required String name}) {
    return showDialog(
      context: context,
      builder: (context) => SaveDeckDialog(initialName: name),
    );
  }

  final String initialName;

  @override
  State<SaveDeckDialog> createState() => _SaveDeckDialogState();
}

class _SaveDeckDialogState extends State<SaveDeckDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const .tightFor(width: 420),
        child: Padding(
          padding: const .all(24),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            spacing: 16,
            children: [
              const SdTitle('Save this deck'),
              const SdCaption(
                'The deck, its artwork and its theme are written to your '
                'SuperDeck folder. Saving again keeps both copies.',
              ),
              SdTextField(
                controller: _controller,
                label: 'Deck name',
                onSubmitted: (_) => _submit(),
                textInputAction: .done,
                autofocus: true,
                semanticLabel: 'Deck name',
              ),
              Row(
                mainAxisAlignment: .end,
                spacing: 10,
                children: [
                  SdButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                    variant: .ghost,
                  ),
                  SdButton(
                    label: 'Save deck',
                    onPressed: _submit,
                    icon: LucideIcons.save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
