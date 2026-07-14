import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:provider/provider.dart';
import 'package:remix/remix.dart';

import '../../../../core/domain/stores/deck_customization_store.dart';
import '../../../ai/quick_agent/domain/commands/generate_deck_command.dart';
import '../../../ai/quick_agent/presentation/widgets/agent_generate_panel.dart';
import '../../domain/stores/editor_store.dart';
import 'color_control.dart';
import 'committed_text_field.dart';
import 'labels.dart';

class CustomizationSidebar extends StatefulWidget {
  const CustomizationSidebar({super.key});

  @override
  State<CustomizationSidebar> createState() => _CustomizationSidebarState();
}

class _CustomizationSidebarState extends State<CustomizationSidebar> {
  late final RemixAccordionController<TextLevel> _accordionController;

  @override
  void initState() {
    super.initState();
    _accordionController = RemixAccordionController<TextLevel>();
  }

  @override
  void dispose() {
    _accordionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = context.select<EditorStore, double>(
      (store) => store.customizationSidebarWidth,
    );

    return Box(
      style: BoxStyler().width(width).marginAll(16).clipBehavior(.none),
      child: ColumnBox(
        style: FlexBoxStyler().crossAxisAlignment(.stretch).clipBehavior(.none),
        children: [
          const _Toolbar(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: const HeroDivider(),
          ),
          Expanded(
            child: _EditorTab(accordionController: _accordionController),
          ),
        ],
      ),
    );
  }
}

class _EditorTab extends StatelessWidget {
  const _EditorTab({required this.accordionController});

  final RemixAccordionController<TextLevel> accordionController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      clipBehavior: Clip.none,
      child: ColumnBox(
        style: FlexBoxStyler().crossAxisAlignment(.stretch).clipBehavior(.none),
        children: [
          const _BackgroundSection(),
          const SizedBox(height: 16),
          const HeroDivider(),
          const SizedBox(height: 16),
          RemixAccordionGroup<TextLevel>(
            controller: accordionController,
            child: ColumnBox(
              style: FlexBoxStyler().crossAxisAlignment(.stretch).spacing(16),
              children: const [
                _LevelAccordion(level: TextLevel.h1, title: 'Heading 1'),
                HeroDivider(),
                _LevelAccordion(level: TextLevel.h2, title: 'Heading 2'),
                HeroDivider(),
                _LevelAccordion(level: TextLevel.h3, title: 'Heading 3'),
                HeroDivider(),
                _LevelAccordion(level: TextLevel.h4, title: 'Heading 4'),
                HeroDivider(),
                _LevelAccordion(level: TextLevel.h5, title: 'Heading 5'),
                HeroDivider(),
                _LevelAccordion(level: TextLevel.h6, title: 'Heading 6'),
                HeroDivider(),
                _LevelAccordion(level: TextLevel.p, title: 'Paragraph'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelAccordion extends StatelessWidget {
  const _LevelAccordion({required this.level, required this.title});

  final TextLevel level;
  final String title;

  @override
  Widget build(BuildContext context) {
    return RemixAccordion<TextLevel>(
      value: level,
      title: title,
      trailingIcon: CupertinoIcons.plus,
      style: RemixAccordionStyle()
          .titleColor($foreground())
          .titleStyle($labelMedium.mix())
          .trailingIconColor($muted())
          .trailingIconSize(18)
          .content(.clipBehavior(.none).padding(.bottom(8).left(1))),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: _LevelControls(level: level),
      ),
    );
  }
}

class _BackgroundSection extends StatelessWidget {
  const _BackgroundSection();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DeckCustomizationStore>();
    return ColumnBox(
      style: FlexBoxStyler().spacing(8).crossAxisAlignment(.stretch),
      children: [
        const SectionLabel('Background'),
        ColorControl(
          color: store.background,
          onChanged: (color) => store.background = color,
        ),
      ],
    );
  }
}

class _LevelControls extends StatelessWidget {
  const _LevelControls({required this.level});

  final TextLevel level;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DeckCustomizationStore>();
    final style = store.level(level);

    return ColumnBox(
      style: FlexBoxStyler().spacing(16).crossAxisAlignment(.stretch),
      children: [
        ColorControl(
          color: style.color,
          onChanged: (color) => store.setColor(level, color),
        ),
        _FontSizeField(level: level),
        _FontWeightSlider(level: level),
        _FontFamilySelect(level: level),
      ],
    );
  }
}

class _FontSizeField extends StatelessWidget {
  const _FontSizeField({required this.level});

  static const _minSize = 8;
  static const _maxSize = 128;

  final TextLevel level;

  static String _format(double size) => size.toInt().toString();

  /// Parses the field and clamps to [_minSize, _maxSize], or null to reject.
  static double? _parse(String text) {
    final parsed = int.tryParse(text.trim());
    if (parsed == null) return null;
    return parsed.clamp(_minSize, _maxSize).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DeckCustomizationStore>();

    return ColumnBox(
      style: FlexBoxStyler().spacing(4).crossAxisAlignment(.start),
      children: [
        const ControlLabel('Size'),
        CommittedTextField<double>(
          value: store.level(level).size,
          format: _format,
          parse: _parse,
          onChanged: (size) => store.setSize(level, size),
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }
}

class _FontWeightSlider extends StatelessWidget {
  const _FontWeightSlider({required this.level});

  final TextLevel level;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DeckCustomizationStore>();
    final weight = store.level(level).weight;

    return ColumnBox(
      style: FlexBoxStyler().spacing(2).crossAxisAlignment(.start),
      children: [
        RowBox(
          style: FlexBoxStyler().mainAxisAlignment(.spaceBetween),
          children: [
            const ControlLabel('Weight'),
            StyledText(
              weight.toString(),
              style: TextStyler().color($foreground()).style($labelSmall.mix()),
            ),
          ],
        ),
        HeroSlider(
          min: 100,
          max: 900,
          snapDivisions: 8,
          showOutput: false,
          value: weight.toDouble(),
          onChanged: (value) =>
              store.setWeight(level, (value / 100).round() * 100),
        ),
      ],
    );
  }
}

class _FontFamilySelect extends StatelessWidget {
  const _FontFamilySelect({required this.level});

  final TextLevel level;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DeckCustomizationStore>();
    final family = store.level(level).family;
    final items = [
      for (final option in playgroundFontFamilies)
        HeroSelectItem<String>(value: option, label: option),
    ];

    return ColumnBox(
      style: FlexBoxStyler().spacing(4).crossAxisAlignment(.start),
      children: [
        const ControlLabel('Family'),
        HeroSelect<String>(
          fullWidth: true,
          placeholder: 'Font',
          items: items,
          icon: CupertinoIcons.textformat,
          selectedValue: family,
          style: .new().trigger(.new().spacing(12)),
          onChanged: (value) {
            if (value != null) store.setFamily(level, value);
          },
        ),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar();

  @override
  Widget build(BuildContext context) {
    return RowBox(
      style: FlexBoxStyler().spacing(8),
      children: [
        const Spacer(),
        // TODO(ai): re-introduce the remaining deck-edit entry points once
        // those features are ported.
        SizedBox(
          width: 48,
          child: HeroIconButton(
            size: .lg,
            variant: .secondary,
            icon: CupertinoIcons.sparkles,
            onPressed: () => showAgentGeneratePanel(
              context,
              context.read<GenerateDeckCommand>(),
            ),
          ),
        ),
        SizedBox(
          width: 48,
          child: HeroIconButton(
            size: .lg,
            icon: CupertinoIcons.play,
            onPressed: () => context.push(
              '/present/${context.read<EditorStore>().activeSlideIndex}',
            ),
          ),
        ),
      ],
    );
  }
}
