import 'package:flutter/material.dart';

import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:genui/genui.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../schemas/genui_action_schema.dart';
import 'user_action_dispatch.dart';
import '../../ui/ui.dart';

import 'catalog_question_step.dart';
import 'component_schema.dart';
import 'typed_catalog_item.dart';

part 'ask_user_slider.g.dart';

// ─────────────────────────────────── SCHEMA ───────────────────────────────────

/// Schema for AskUserSlider component.
///
/// Displays a question with a focused numeric selector.
@AckType(name: 'AskUserSlider')
final _askUserSliderSchema = Ack.object({
  'question': Ack.string().describe('The question to display to the user'),
  'description': Ack.string().optional().describe(
    'Additional context or instructions',
  ),
  'minValue': Ack.integer().describe('Minimum value'),
  'maxValue': Ack.integer().describe('Maximum value'),
  'defaultValue': Ack.integer().describe('Default/initial value'),
  'unit': Ack.string().optional().describe(
    'Unit label e.g. "slides", "minutes"',
  ),
  'action': actionSchema,
}).describe('A question with a counter and quick choices between min and max.');

// ─────────────────────────────────── CATALOG ITEM ───────────────────────────────────

/// AskUserSlider catalog component for numeric input questions.
final askUserSlider = typedCatalogItem<AskUserSliderType>(
  name: 'AskUserSlider',
  dataSchema: componentSchema(_askUserSliderSchema.toJsonSchemaBuilder()),
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "AskUserSlider",
          "question": "How many slides do you need?",
          "minValue": 5,
          "maxValue": 20,
          "defaultValue": 10,
          "unit": "slides",
          "action": {"name": "submit_answer", "context": []}
        }
      ]
    ''',
  ],
  parse: AskUserSliderType.parse,
  widgetBuilder: (context, data) =>
      _AskUserSliderContent(data: data, itemContext: context),
);

// ─────────────────────────────────── WIDGET ───────────────────────────────────

/// Focused numeric selector used for the deck-length step.
class DeckLengthSelector extends StatelessWidget {
  const DeckLengthSelector({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.unit = 'slides',
  });

  final int value;
  final int min;
  final int max;
  final String unit;
  final ValueChanged<int> onChanged;

  List<int> get _presets {
    final values = unit.toLowerCase().contains('slide')
        ? [min, 8, 10, 12, 15, 20, max]
        : [min, ((min + max) / 2).round(), max];

    return values.where((item) => item >= min && item <= max).toSet().toList()
      ..sort();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = $accent.resolve(context);
    final mutedColor = $muted.resolve(context);

    final identity = Row(
      mainAxisSize: .min,
      spacing: 12,
      children: [
        Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: $accentSoft.resolve(context),
            borderRadius: .circular(12),
          ),
          width: 44,
          height: 44,
          child: Icon(LucideIcons.presentation, size: 22, color: iconColor),
        ),
        const Flexible(
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            children: [
              SdBody('Deck length'),
              SdCaption('Choose a pace that fits your story'),
            ],
          ),
        ),
      ],
    );

    final counter = Container(
      padding: const .symmetric(vertical: 4, horizontal: 4),
      decoration: BoxDecoration(
        color: $background.resolve(context),
        border: .all(color: $border.resolve(context)),
        borderRadius: .circular(14),
      ),
      child: Row(
        mainAxisSize: .min,
        children: [
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            tooltip: 'One fewer slide',
            icon: const Icon(LucideIcons.minus, size: 18),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints.tightFor(width: 76),
            child: Column(
              mainAxisSize: .min,
              children: [
                Text(
                  '$value',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: $foreground.resolve(context),
                    fontWeight: .w700,
                    height: 1,
                  ),
                ),
                if (unit.isNotEmpty)
                  Text(
                    unit,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: mutedColor),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            tooltip: 'One more slide',
            icon: const Icon(LucideIcons.plus, size: 18),
          ),
        ],
      ),
    );

    return SdPanel(
      child: Column(
        crossAxisAlignment: .start,
        spacing: 18,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: .start,
                  spacing: 16,
                  children: [identity, counter],
                );
              }

              return Row(
                mainAxisAlignment: .spaceBetween,
                spacing: 16,
                children: [
                  Expanded(child: identity),
                  counter,
                ],
              );
            },
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in _presets)
                _DeckLengthPreset(
                  value: preset,
                  selected: preset == value,
                  onTap: () => onChanged(preset),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeckLengthPreset extends StatelessWidget {
  const _DeckLengthPreset({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: '$value slides',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: .circular(10),
          child: AnimatedContainer(
            padding: const .symmetric(vertical: 9, horizontal: 14),
            decoration: BoxDecoration(
              color: selected
                  ? $accentSoft.resolve(context)
                  : $background.resolve(context),
              border: .all(
                color: selected
                    ? $accent.resolve(context)
                    : $border.resolve(context),
              ),
              borderRadius: .circular(10),
            ),
            duration: SdTokens.motionFast,
            child: Text(
              '$value',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected
                    ? $accent.resolve(context)
                    : $muted.resolve(context),
                fontWeight: .w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AskUserSliderContent extends StatefulWidget {
  final AskUserSliderType data;
  final CatalogItemContext itemContext;

  const _AskUserSliderContent({required this.data, required this.itemContext});

  @override
  State<_AskUserSliderContent> createState() => _AskUserSliderContentState();
}

class _AskUserSliderContentState extends State<_AskUserSliderContent> {
  int _sliderValue = 0;

  @override
  void initState() {
    super.initState();
    final minVal = widget.data.minValue;
    final maxVal = widget.data.maxValue;
    final defaultVal = widget.data.defaultValue;
    _sliderValue = _clampToRange(defaultVal, min: minVal, max: maxVal);
  }

  int _clampToRange(int value, {required int min, required int max}) {
    return value.clamp(min, max).toInt();
  }

  Map<String, dynamic> _buildActionContext() {
    return {'value': _sliderValue};
  }

  void _submitAction() => submitCatalogActionIfValid(
    canSubmit: true,
    itemContext: widget.itemContext,
    action: widget.data.action,
    contextBuilder: _buildActionContext,
  );

  Widget _buildSlider() {
    final minValue = widget.data.minValue;
    final maxValue = widget.data.maxValue;
    final unit = widget.data.unit ?? '';

    return DeckLengthSelector(
      value: _sliderValue,
      min: minValue,
      max: maxValue,
      onChanged: (value) => setState(() => _sliderValue = value),
      unit: unit,
    );
  }

  @override
  void didUpdateWidget(covariant _AskUserSliderContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    final minChanged = oldWidget.data.minValue != widget.data.minValue;
    final maxChanged = oldWidget.data.maxValue != widget.data.maxValue;
    final defaultChanged =
        oldWidget.data.defaultValue != widget.data.defaultValue;

    final minValue = widget.data.minValue;
    final maxValue = widget.data.maxValue;
    if (defaultChanged) {
      _sliderValue = _clampToRange(
        widget.data.defaultValue,
        min: minValue,
        max: maxValue,
      );
      return;
    }

    if (minChanged || maxChanged) {
      _sliderValue = _clampToRange(_sliderValue, min: minValue, max: maxValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CatalogQuestionStep(
      question: widget.data.question,
      description: widget.data.description,
      body: _buildSlider(),
      onSubmit: _submitAction,
    );
  }
}
