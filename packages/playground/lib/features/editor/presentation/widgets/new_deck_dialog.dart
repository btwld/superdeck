import 'package:flutter/cupertino.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:remix/remix.dart';

import '../../../../core/data/data_sources/deck_file_store.dart';
import '../../domain/stores/deck_file_controller.dart';

/// Opens the "New deck" dialog: prompts for a name, creates `<name>.md` in
/// `~/Documents/SuperDeck/`, and rebinds the editor. On a name collision it
/// re-prompts with an inline error rather than overwriting.
///
/// [controller] is captured from the editor's provider scope; the dialog route
/// does not inherit it reliably.
Future<void> showNewDeckDialog(
  BuildContext context,
  DeckFileController controller,
) {
  return showRemixDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _NewDeckDialog(controller: controller),
  );
}

class _NewDeckDialog extends StatefulWidget {
  const _NewDeckDialog({required this.controller});

  final DeckFileController controller;

  @override
  State<_NewDeckDialog> createState() => _NewDeckDialogState();
}

class _NewDeckDialogState extends State<_NewDeckDialog> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  String? _error;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _textController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name for your deck.');
      return;
    }
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      await widget.controller.newDeck(name);
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } on DeckNameCollisionException catch (e) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _error = '${e.fileName} already exists. Choose another name.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _error = 'Could not create the deck: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: HeroCard(
        style: RemixCardStyle().maxWidth(440).paddingAll(24),
        child: ColumnBox(
          style: FlexBoxStyler()
              .mainAxisSize(.min)
              .spacing(12)
              .crossAxisAlignment(.end),
          children: [
            RowBox(
              style: FlexBoxStyler().mainAxisAlignment(.spaceBetween),
              children: [
                StyledText(
                  'New deck',
                  style: TextStyler()
                      .color($foreground())
                      .style($labelMedium.mix()),
                ),
                SizedBox(
                  width: 36,
                  child: HeroIconButton(
                    icon: CupertinoIcons.xmark,
                    size: .sm,
                    variant: .ghost,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ],
            ),
            HeroTextField(
              fullWidth: true,
              autofocus: true,
              controller: _textController,
              focusNode: _focusNode,
              enabled: !_creating,
              error: _error != null,
              hintText: 'my-presentation',
              helperText: 'Saved as a .md file in Documents/SuperDeck',
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _create(),
            ),
            if (_error != null)
              Box(
                style: BoxStyler()
                    .width(double.infinity)
                    .color($danger().withValues(alpha: 0.1))
                    .borderRounded(8)
                    .paddingAll(12),
                child: StyledText(
                  _error!,
                  style: TextStyler().color($danger()).style($labelSmall.mix()),
                ),
              ),
            HeroButton(
              label: 'Create',
              iconLeft: CupertinoIcons.add,
              loading: _creating,
              onPressed: _creating ? null : _create,
            ),
          ],
        ),
      ),
    );
  }
}
