import 'package:flutter/material.dart';

import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:genui/genui.dart';
import 'package:remix/remix.dart';

import '../schemas/genui_action_schema.dart';
import './user_action_dispatch.dart';
import '../../ui/ui.dart';

import 'catalog_question_step.dart';

part 'ask_user_slider.g.dart';

// ─────────────────────────────────── SCHEMA ───────────────────────────────────

/// Schema for AskUserSlider component.
///
/// Displays a question with a slider for numeric input.
@AckType(name: 'AskUserSlider')
final _askUserSliderSchema =
    Ack.object({
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
    }).describe(
      'A question with a slider for numeric selection between min and max.',
    );

// ─────────────────────────────────── CATALOG ITEM ───────────────────────────────────

/// AskUserSlider catalog component for numeric input questions.
final askUserSlider = CatalogItem(
  name: 'AskUserSlider',
  dataSchema: _askUserSliderSchema.toJsonSchemaBuilder(),
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "AskUserSlider": {
              "question": "How many slides do you need?",
              "minValue": 5,
              "maxValue": 25,
              "defaultValue": 10,
              "unit": "slides",
              "action": {"name": "submit_answer", "context": []}
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = AskUserSliderType.parse(context.data);
    return _AskUserSliderContent(data: data, itemContext: context);
  },
);

// ─────────────────────────────────── WIDGET ───────────────────────────────────

class _AskUserSliderContent extends StatefulWidget {
  final AskUserSliderType data;
  final CatalogItemContext itemContext;

  const _AskUserSliderContent({required this.data, required this.itemContext});

  @override
  State<_AskUserSliderContent> createState() => _AskUserSliderContentState();
}

class _AskUserSliderContentState extends State<_AskUserSliderContent> {
  int _sliderValue = 0;

  int _clampToRange(int value, {required int min, required int max}) {
    return value.clamp(min, max).toInt();
  }

  @override
  void initState() {
    super.initState();
    final minVal = widget.data.minValue;
    final maxVal = widget.data.maxValue;
    final defaultVal = widget.data.defaultValue;
    _sliderValue = _clampToRange(defaultVal, min: minVal, max: maxVal);
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

  Map<String, dynamic> _buildActionContext() {
    final unit = widget.data.unit ?? '';
    return {
      'value': _sliderValue,
      'message': '$_sliderValue${unit.isNotEmpty ? ' $unit' : ''}',
    };
  }

  void _submitAction() => submitCatalogActionIfValid(
    canSubmit: true,
    itemContext: widget.itemContext,
    rawAction: widget.data.action,
    contextBuilder: _buildActionContext,
  );

  @override
  Widget build(BuildContext context) {
    return CatalogQuestionStep(
      question: widget.data.question,
      description: widget.data.description,
      body: _buildSlider(),
      onSubmit: _submitAction,
    );
  }

  Widget _buildSlider() {
    final minValue = widget.data.minValue;
    final maxValue = widget.data.maxValue;

    final labelStyle = TextStyler()
        .color(FortalTokens.gray11())
        .style(FortalTokens.text2.mix());

    final valueStyle = TextStyler()
        .color(FortalTokens.accent11())
        .style(FortalTokens.text6.mix())
        .fontWeight(.bold)
        .wrap(
          WidgetModifierConfig()
              .sizedBox(width: 120)
              .align(alignment: .centerRight),
        );

    final unit = widget.data.unit ?? '';
    final displayValue = '$_sliderValue${unit.isNotEmpty ? ' $unit' : ''}';

    return SdPanel(
      child: Row(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          labelStyle('$minValue'),
          Expanded(
            child: SdSlider(
              value: _sliderValue.toDouble(),
              min: minValue.toDouble(),
              max: maxValue.toDouble(),
              onChanged: (value) {
                setState(() => _sliderValue = value.round());
              },
            ),
          ),
          labelStyle('$maxValue'),
          valueStyle(displayValue),
        ],
      ),
    );
  }
}
