import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:provider/provider.dart';
import 'package:remix/remix.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../stores/ai_store.dart';
import '../../stores/deck_customization_store.dart';
import '../../utils/text_editor_controller.dart';
import '../ai/ai_generate_panel.dart';

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
    return Box(
      style: BoxStyler().width(280).marginAll(16).clipBehavior(.none),
      child: ColumnBox(
        style: FlexBoxStyler().crossAxisAlignment(.stretch).clipBehavior(.none),
        children: [
          const _Toolbar(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: const HeroDivider(),
          ),
          Expanded(
            child: SingleChildScrollView(
              clipBehavior: Clip.none,
              child: ColumnBox(
                style: FlexBoxStyler()
                    .crossAxisAlignment(.stretch)
                    .clipBehavior(.none),
                children: [
                  const _BackgroundSection(),
                  const SizedBox(height: 16),
                  const HeroDivider(),
                  const SizedBox(height: 16),
                  RemixAccordionGroup<TextLevel>(
                    controller: _accordionController,
                    child: ColumnBox(
                      style: FlexBoxStyler()
                          .crossAxisAlignment(.stretch)
                          .spacing(16),
                      children: const [
                        _LevelAccordion(
                          level: TextLevel.h1,
                          title: 'Heading 1',
                        ),
                        HeroDivider(),
                        _LevelAccordion(
                          level: TextLevel.h2,
                          title: 'Heading 2',
                        ),
                        HeroDivider(),
                        _LevelAccordion(
                          level: TextLevel.h3,
                          title: 'Heading 3',
                        ),
                        HeroDivider(),
                        _LevelAccordion(level: TextLevel.p, title: 'Paragraph'),
                      ],
                    ),
                  ),
                ],
              ),
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
    final store = context.read<DeckCustomizationStore>();
    return ColumnBox(
      style: FlexBoxStyler().spacing(8).crossAxisAlignment(.start),
      children: [
        const _SectionLabel('Background'),
        Watch((context) {
          return _SwatchRow(
            swatches: playgroundBackgroundSwatches,
            selected: store.background.value,
            onSelected: (color) => store.background.value = color,
          );
        }),
      ],
    );
  }
}

class _LevelControls extends StatelessWidget {
  const _LevelControls({required this.level});

  final TextLevel level;

  @override
  Widget build(BuildContext context) {
    final store = context.read<DeckCustomizationStore>();
    final signals = store.level(level);

    return ColumnBox(
      style: FlexBoxStyler().spacing(16).crossAxisAlignment(.stretch),
      children: [
        Watch((context) {
          return _SwatchRow(
            swatches: playgroundTextSwatches,
            selected: signals.color.value,
            onSelected: (color) => signals.color.value = color,
          );
        }),
        _FontSizeField(level: level),
        _FontWeightSlider(level: level),
        _FontFamilySelect(level: level),
      ],
    );
  }
}

class _SwatchRow extends StatelessWidget {
  const _SwatchRow({
    required this.swatches,
    required this.selected,
    required this.onSelected,
  });

  final List<PlaygroundSwatch> swatches;
  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    return RowBox(
      style: FlexBoxStyler().spacing(8),
      children: [
        for (final swatch in swatches)
          Pressable(
            onPress: () => onSelected(swatch.color),
            child: Box(
              style: BoxStyler()
                  .width(28)
                  .height(28)
                  .color(swatch.color)
                  .borderRounded(999)
                  .shadowOnly(
                    color: swatch.color == selected ? $accent() : $background(),
                    offset: Offset(0, 0),
                    blurRadius: 0,
                    spreadRadius: 2,
                  )
                  .borderAll(
                    color: swatch.color == selected ? $background() : $border(),
                    width: swatch.color == selected ? 2 : 1,
                  ),
            ),
          ),
      ],
    );
  }
}

class _FontSizeField extends StatefulWidget {
  const _FontSizeField({required this.level});

  final TextLevel level;

  @override
  State<_FontSizeField> createState() => _FontSizeFieldState();
}

class _FontSizeFieldState extends State<_FontSizeField> {
  static const _minSize = 8;
  static const _maxSize = 128;

  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final EffectCleanup _externalCleanup;

  @override
  void initState() {
    super.initState();
    final store = context.read<DeckCustomizationStore>();
    final signal = store.level(widget.level).size;
    _controller = TextEditingController(text: signal.peek().toInt().toString());
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
    // Pull external mutations (e.g., future reset action) into the field.
    _externalCleanup = effect(() {
      final value = signal.value;
      if (_focusNode.hasFocus) return;
      final expected = value.toInt().toString();
      if (_controller.text != expected) _controller.text = expected;
    });
  }

  @override
  void dispose() {
    _externalCleanup();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) _commit();
  }

  /// Parses the field, clamps to [_minSize, _maxSize], and either writes to the
  /// signal or rewrites the field with the last known good value.
  void _commit() {
    final store = context.read<DeckCustomizationStore>();
    final signal = store.level(widget.level).size;
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null) {
      _controller.text = signal.peek().toInt().toString();
      return;
    }
    final clamped = parsed.clamp(_minSize, _maxSize);
    signal.value = clamped.toDouble();
    _controller.text = clamped.toString();
  }

  @override
  Widget build(BuildContext context) {
    return ColumnBox(
      style: FlexBoxStyler().spacing(4).crossAxisAlignment(.start),
      children: [
        const _ControlLabel('Size'),
        HeroTextField(
          fullWidth: true,
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onSubmitted: (_) => _commit(),
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
    final store = context.read<DeckCustomizationStore>();
    final signal = store.level(level).weight;

    return Watch((context) {
      final weight = signal.value;
      return ColumnBox(
        style: FlexBoxStyler().spacing(2).crossAxisAlignment(.start),
        children: [
          RowBox(
            style: FlexBoxStyler().mainAxisAlignment(.spaceBetween),
            children: [
              const _ControlLabel('Weight'),
              StyledText(
                weight.toString(),
                style: TextStyler()
                    .color($foreground())
                    .style($labelSmall.mix()),
              ),
            ],
          ),
          HeroSlider(
            min: 100,
            max: 900,
            snapDivisions: 8,
            showOutput: false,
            value: weight.toDouble(),
            onChanged: (value) => signal.value = (value / 100).round() * 100,
          ),
        ],
      );
    });
  }
}

class _FontFamilySelect extends StatelessWidget {
  const _FontFamilySelect({required this.level});

  final TextLevel level;

  @override
  Widget build(BuildContext context) {
    final store = context.read<DeckCustomizationStore>();
    final signal = store.level(level).family;
    final items = [
      for (final family in playgroundFontFamilies)
        HeroSelectItem<String>(value: family, label: family),
    ];

    return ColumnBox(
      style: FlexBoxStyler().spacing(4).crossAxisAlignment(.start),
      children: [
        const _ControlLabel('Family'),
        Watch((context) {
          return HeroSelect<String>(
            fullWidth: true,
            placeholder: 'Font',
            items: items,
            icon: CupertinoIcons.textformat,
            selectedValue: signal.value,
            style: .new().trigger(.new().spacing(12)),
            onChanged: (value) {
              if (value != null) signal.value = value;
            },
          );
        }),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return StyledText(
      text,
      style: TextStyler()
          .color($foreground())
          .style($labelMedium.mix())
          .wrap(.padding(.vertical(4))),
    );
  }
}

class _ControlLabel extends StatelessWidget {
  const _ControlLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return StyledText(
      text,
      style: TextStyler().color($muted()).style($labelSmall.mix()),
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
        Spacer(),
        // Simple AI prompt panel (quick text-entry shortcut).
        SizedBox(
          width: 48,
          child: HeroIconButton(
            icon: CupertinoIcons.sparkles,
            size: .lg,
            variant: .secondary,
            onPressed: () =>
                showAiGeneratePanel(context, context.read<AiStore>()),
          ),
        ),
        SizedBox(
          width: 48,
          child: HeroIconButton(
            icon: CupertinoIcons.text_bubble,
            size: .lg,
            variant: .secondary,
            onPressed: () {
              final editorController = context.read<TextEditorController>();
              final capturedSource = editorController.latestMarkdown;
              editorController.suspendOutboundWritesForAiEntry();
              Navigator.of(
                context,
              ).pushReplacementNamed('/ai/edit', arguments: capturedSource);
            },
          ),
        ),
        // Full 8-step GenUI wizard.
        SizedBox(
          width: 48,
          child: HeroIconButton(
            icon: CupertinoIcons.wand_stars,
            size: .lg,
            variant: .secondary,
            onPressed: () => Navigator.of(context).pushNamed('/ai/wizard'),
          ),
        ),
        // Remix component builder.
        SizedBox(
          width: 48,
          child: HeroIconButton(
            icon: CupertinoIcons.cube_box,
            size: .lg,
            variant: .secondary,
            onPressed: () => Navigator.of(context).pushNamed('/ai/remix'),
          ),
        ),
        SizedBox(
          width: 48,
          child: HeroIconButton(
            size: .lg,
            icon: CupertinoIcons.play,
            onPressed: () {
              Navigator.of(context).pushNamed('/present');
            },
          ),
        ),
      ],
    );
  }
}
