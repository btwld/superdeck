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

  final DeckPlanType plan;
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

  @override
  void didUpdateWidget(covariant WizardOutlineReview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.planRevision != widget.planRevision) {
      _invalidSlideKeys.clear();
    }
    final currentKeys = widget.plan.slides.map((slide) => slide.key).toSet();
    _invalidSlideKeys.removeWhere((key) => !currentKeys.contains(key));
  }

  void _setSlideValidity(String key, bool isValid) {
    setState(() {
      if (isValid) {
        _invalidSlideKeys.remove(key);
      } else {
        _invalidSlideKeys.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 18,
            children: [
              SdPanel(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 14,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: $accentSoft.resolve(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        LucideIcons.listTree,
                        size: 22,
                        color: $accent.resolve(context),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                    for (final (index, slide) in widget.plan.slides.indexed)
                      if (slide.sectionKey == section.key)
                        (index: index, slide: slide),
                  ],
                  onSlideChanged: widget.onSlideChanged,
                  onSlideValidityChanged: _setSlideValidity,
                  planRevision: widget.planRevision,
                ),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 10,
                children: [
                  TextButton(
                    onPressed: widget.onBack,
                    child: const Text('Back'),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.onRegenerate,
                    icon: const Icon(LucideIcons.refreshCw, size: 17),
                    label: const Text('Regenerate outline'),
                  ),
                  SdButton(
                    label: 'Approve & build',
                    icon: LucideIcons.sparkles,
                    onPressed: _invalidSlideKeys.isEmpty
                        ? widget.onApprove
                        : null,
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

class _OutlineSection extends StatelessWidget {
  const _OutlineSection({
    required this.section,
    required this.slides,
    required this.onSlideChanged,
    required this.onSlideValidityChanged,
    required this.planRevision,
  });

  final DeckPlanSectionType section;
  final List<({int index, DeckPlanSlideType slide})> slides;
  final UpdateOutlineSlide onSlideChanged;
  final void Function(String key, bool isValid) onSlideValidityChanged;
  final int planRevision;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [SdTitle(section.title), SdCaption(section.purpose)],
          ),
        ),
        for (final item in slides)
          _OutlineSlideEditor(
            key: ValueKey(item.slide.key),
            index: item.index,
            slide: item.slide,
            onChanged: onSlideChanged,
            onValidityChanged: (isValid) =>
                onSlideValidityChanged(item.slide.key, isValid),
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
    required this.onChanged,
    required this.onValidityChanged,
    required this.planRevision,
  });

  final int index;
  final DeckPlanSlideType slide;
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
  Widget build(BuildContext context) {
    final slide = widget.slide;
    final borderColor = $border.resolve(context);

    return SdPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: $surfaceTertiary.resolve(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            alignment: Alignment.center,
            child: SdCaption('Slide ${widget.index + 1}'),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                SdTextField(
                  key: ValueKey('outline-title-${slide.key}'),
                  controller: _titleController,
                  label: 'Slide title',
                  semanticLabel: 'Slide ${widget.index + 1} title',
                  textInputAction: TextInputAction.next,
                  onChanged: _submitEdit,
                ),
                SdTextField(
                  key: ValueKey('outline-assertion-${slide.key}'),
                  controller: _assertionController,
                  label: 'Core message',
                  semanticLabel: 'Slide ${widget.index + 1} core message',
                  minLines: 1,
                  maxLines: 2,
                  onChanged: _submitEdit,
                ),
                if (_validationMessage case final message?)
                  Text(
                    message,
                    style: TextStyle(
                      color: $danger.resolve(context),
                      fontSize: 12,
                    ),
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PlanChip(label: slide.narrativeRole),
                    _PlanChip(label: slide.composition),
                    _PlanChip(label: slide.treatment),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  const _PlanChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: $surfaceTertiary.resolve(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: SdCaption(label),
    );
  }
}
