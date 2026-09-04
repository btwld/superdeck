import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../quick_agent/core/engine/schemas/outline_schema.dart';
import '../core/ui/ui.dart';

typedef UpdateOutlineSlide =
    bool Function(int index, String title, String assertion);

/// Editable review of the exact typed plan that slide composition will use.
class WizardOutlineReview extends StatefulWidget {
  const WizardOutlineReview({
    super.key,
    required this.plan,
    this.planRevision = 0,
    required this.onSlideChanged,
    required this.onBack,
    required this.onRegenerate,
    required this.onApprove,
  });

  final DeckPlan plan;
  final int planRevision;
  final UpdateOutlineSlide onSlideChanged;
  final VoidCallback onBack;
  final VoidCallback onRegenerate;
  final VoidCallback onApprove;

  @override
  State<WizardOutlineReview> createState() => _WizardOutlineReviewState();
}

class _WizardOutlineReviewState extends State<WizardOutlineReview> {
  final _invalidSlideKeys = <String>{};
  String? _editingSlideKey;

  void _setSlideValidity(String key, {required bool isValid}) {
    setState(() {
      if (isValid) {
        _invalidSlideKeys.remove(key);
      } else {
        _invalidSlideKeys.add(key);
      }
    });
  }

  @override
  void didUpdateWidget(covariant WizardOutlineReview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.planRevision != widget.planRevision) {
      _invalidSlideKeys.clear();
      _editingSlideKey = null;
    }
    final currentKeys = widget.plan.slides.map((slide) => slide.key).toSet();
    _invalidSlideKeys.removeWhere((key) => !currentKeys.contains(key));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const .symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: .stretch,
                  spacing: 18,
                  children: [
                    SdPanel(
                      child: Row(
                        crossAxisAlignment: .start,
                        spacing: 14,
                        children: [
                          Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: $accentSoft.resolve(context),
                              borderRadius: .circular(12),
                            ),
                            width: 44,
                            height: 44,
                            child: Icon(
                              LucideIcons.listTree,
                              size: 22,
                              color: $accent.resolve(context),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: .start,
                              spacing: 6,
                              children: [
                                const SdHeadline('Review the story'),
                                SdBody(widget.plan.story),
                                SdCaption(
                                  '${widget.plan.slides.length} slides across '
                                  '${widget.plan.sections.length} sections',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final section in widget.plan.sections)
                      _OutlineSection(
                        section: section,
                        slides: [
                          for (final (index, slide)
                              in widget.plan.slides.indexed)
                            if (slide.sectionKey == section.key)
                              (index: index, slide: slide),
                        ],
                        editingSlideKey: _editingSlideKey,
                        onEdit: (key) => setState(() {
                          _editingSlideKey = key;
                        }),
                        onSlideChanged: widget.onSlideChanged,
                        onSlideValidityChanged: _setSlideValidity,
                        planRevision: widget.planRevision,
                      ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const .symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: $background.resolve(context),
                  border: Border(
                    top: BorderSide(color: $border.resolve(context)),
                  ),
                ),
                child: Wrap(
                  alignment: .end,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SdButton(
                      label: 'Back',
                      onPressed: widget.onBack,
                      variant: .ghost,
                    ),
                    SdButton(
                      label: 'Regenerate outline',
                      onPressed: widget.onRegenerate,
                      icon: LucideIcons.refreshCw,
                      variant: .outline,
                    ),
                    SdButton(
                      label: 'Approve & build',
                      onPressed: _invalidSlideKeys.isEmpty
                          ? widget.onApprove
                          : null,
                      icon: LucideIcons.sparkles,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineSection extends StatelessWidget {
  const _OutlineSection({
    required this.section,
    required this.slides,
    required this.editingSlideKey,
    required this.onEdit,
    required this.onSlideChanged,
    required this.onSlideValidityChanged,
    required this.planRevision,
  });

  final DeckPlanSection section;
  final List<({int index, DeckPlanSlide slide})> slides;
  final String? editingSlideKey;
  final ValueChanged<String?> onEdit;
  final UpdateOutlineSlide onSlideChanged;
  final void Function(String key, {required bool isValid})
  onSlideValidityChanged;
  final int planRevision;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      spacing: 10,
      children: [
        Padding(
          padding: const .symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: .stretch,
            spacing: 4,
            children: [SdTitle(section.title), SdCaption(section.purpose)],
          ),
        ),
        for (final item in slides)
          _OutlineSlideEditor(
            key: ValueKey(item.slide.key),
            index: item.index,
            slide: item.slide,
            editing: editingSlideKey == item.slide.key,
            onEdit: onEdit,
            onChanged: onSlideChanged,
            onValidityChanged: (isValid) =>
                onSlideValidityChanged(item.slide.key, isValid: isValid),
            planRevision: planRevision,
          ),
      ],
    );
  }
}

class _OutlineSlideEditor extends StatefulWidget {
  const _OutlineSlideEditor({
    super.key,
    required this.index,
    required this.slide,
    required this.editing,
    required this.onEdit,
    required this.onChanged,
    required this.onValidityChanged,
    required this.planRevision,
  });

  final int index;
  final DeckPlanSlide slide;
  final bool editing;
  final ValueChanged<String?> onEdit;
  final UpdateOutlineSlide onChanged;
  final ValueChanged<bool> onValidityChanged;
  final int planRevision;

  @override
  State<_OutlineSlideEditor> createState() => _OutlineSlideEditorState();
}

class _OutlineSlideEditorState extends State<_OutlineSlideEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _assertionController;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.slide.title);
    _assertionController = TextEditingController(text: widget.slide.assertion);
  }

  void _submitEdit(String _) {
    final title = _titleController.text.trim();
    final assertion = _assertionController.text.trim();
    if (title.isEmpty || assertion.isEmpty) {
      setState(() {
        _validationMessage = 'Add both a slide title and core message.';
      });
      widget.onValidityChanged(false);

      return;
    }
    final accepted = widget.onChanged(widget.index, title, assertion);
    setState(() {
      _validationMessage = accepted
          ? null
          : 'This edit conflicts with the approved deck constraints.';
    });
    widget.onValidityChanged(accepted);
  }

  @override
  void didUpdateWidget(covariant _OutlineSlideEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.planRevision != widget.planRevision) {
      _titleController.text = widget.slide.title;
      _assertionController.text = widget.slide.assertion;
      _validationMessage = null;

      return;
    }
    if (oldWidget.slide.title != widget.slide.title &&
        _titleController.text != widget.slide.title) {
      _titleController.text = widget.slide.title;
    }
    if (oldWidget.slide.assertion != widget.slide.assertion &&
        _assertionController.text != widget.slide.assertion) {
      _assertionController.text = widget.slide.assertion;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _assertionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = widget.slide;
    final borderColor = $border.resolve(context);

    return SdPanel(
      child: Row(
        crossAxisAlignment: .start,
        spacing: 14,
        children: [
          Container(
            alignment: Alignment.center,
            padding: const .symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: $surfaceTertiary.resolve(context),
              border: .all(color: borderColor),
              borderRadius: .circular(10),
            ),
            width: 58,
            child: SdCaption('Slide ${widget.index + 1}'),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              spacing: widget.editing ? 12 : 4,
              children: [
                if (widget.editing) ...[
                  SdTextField(
                    key: ValueKey('outline-title-${slide.key}'),
                    controller: _titleController,
                    label: 'Slide title',
                    onChanged: _submitEdit,
                    textInputAction: .next,
                    semanticLabel: 'Slide ${widget.index + 1} title',
                  ),
                  SdTextField(
                    key: ValueKey('outline-assertion-${slide.key}'),
                    controller: _assertionController,
                    label: 'Core message',
                    onChanged: _submitEdit,
                    maxLines: 2,
                    minLines: 1,
                    semanticLabel: 'Slide ${widget.index + 1} core message',
                  ),
                ] else ...[
                  SdTitle(slide.title),
                  SdBody(slide.assertion),
                ],
                if (_validationMessage case final message?)
                  Text(
                    message,
                    style: TextStyle(
                      color: $danger.resolve(context),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          SdButton(
            label: widget.editing ? 'Done' : 'Edit slide ${widget.index + 1}',
            onPressed: () => widget.onEdit(widget.editing ? null : slide.key),
            icon: widget.editing ? LucideIcons.check : LucideIcons.pencil,
            variant: .ghost,
          ),
        ],
      ),
    );
  }
}
