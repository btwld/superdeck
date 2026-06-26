import 'package:flutter/material.dart';

import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:genui/genui.dart';
import 'package:remix/remix.dart';

import '../schemas/genui_action_schema.dart';
import 'user_action_dispatch.dart';
import '../../ui/ui.dart';

import 'catalog_question_step.dart';

part 'ask_user_text.g.dart';

// ─────────────────────────────────── SCHEMA ───────────────────────────────────

/// Schema for AskUserText component.
///
/// Displays a question with a text field for free-form input.
@AckType(name: 'AskUserText')
final _askUserTextSchema = Ack.object({
  'question': Ack.string().describe('The question to display to the user'),
  'description': Ack.string().optional().describe(
    'Additional context or instructions',
  ),
  'placeholder': Ack.string().optional().describe('Placeholder text'),
  'maxLength': Ack.integer().optional().describe('Maximum character length'),
  'multiline': Ack.boolean().optional().describe('Allow multiline input'),
  'action': actionSchema,
}).describe('A question with a text field for free-form user input.');

// ─────────────────────────────────── CATALOG ITEM ───────────────────────────────────

/// AskUserText catalog component for free-form text input.
final askUserText = CatalogItem(
  name: 'AskUserText',
  dataSchema: _askUserTextSchema.toJsonSchemaBuilder(),
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "AskUserText": {
              "question": "What is your presentation topic?",
              "description": "Enter a brief description of your topic.",
              "placeholder": "e.g., Introduction to Machine Learning",
              "maxLength": 200,
              "action": {"name": "submit_answer", "context": []}
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final data = AskUserTextType.parse(context.data);
    return _AskUserTextContent(data: data, itemContext: context);
  },
);

// ─────────────────────────────────── WIDGET ───────────────────────────────────

class _AskUserTextContent extends StatefulWidget {
  final AskUserTextType data;
  final CatalogItemContext itemContext;

  const _AskUserTextContent({required this.data, required this.itemContext});

  @override
  State<_AskUserTextContent> createState() => _AskUserTextContentState();
}

class _AskUserTextContentState extends State<_AskUserTextContent> {
  final _textController = TextEditingController();

  bool get _canSubmit => _textController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildActionContext() {
    final text = _textController.text.trim();
    return {'text': text, 'message': text};
  }

  void _submitAction() => submitCatalogActionIfValid(
    canSubmit: _canSubmit,
    itemContext: widget.itemContext,
    rawAction: widget.data.action,
    contextBuilder: _buildActionContext,
  );

  @override
  Widget build(BuildContext context) {
    return CatalogQuestionStep(
      question: widget.data.question,
      description: widget.data.description,
      canSubmit: _canSubmit,
      onSubmit: _submitAction,
      body: SdPanel(
        child: TextField(
          controller: _textController,
          maxLength: widget.data.maxLength,
          maxLines: widget.data.multiline == true ? 4 : 1,
          decoration: InputDecoration(
            hintText: widget.data.placeholder,
            border: InputBorder.none,
            counterText: '',
          ),
          style: FortalTokens.text3.mix().resolve(context),
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }
}
