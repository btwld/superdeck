import 'package:flutter/cupertino.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:remix/remix.dart';

class CustomizationSidebar extends StatelessWidget {
  const CustomizationSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return StackBox(
      style: StackBoxStyler().width(280).marginAll(16),
      children: [
        ColumnBox(
          children: [
            _Toolbar(),
            Padding(
              padding: const .symmetric(vertical: 16),
              child: HeroDivider(),
            ),
            Expanded(child: _TextScalerTool()),
          ],
        ),
      ],
    );
  }
}

class _TextScalerTool extends StatefulWidget {
  const _TextScalerTool();

  @override
  State<_TextScalerTool> createState() => _TextScalerToolState();
}

class _TextScalerToolState extends State<_TextScalerTool> {
  @override
  Widget build(BuildContext context) {
    // final textScaler = context.watch<SlideConfigurationStore>().textScaler;

    return ColumnBox(
      style: FlexBoxStyler().spacing(2).crossAxisAlignment(.start),
      children: [
        RowBox(
          children: [
            StyledText(
              'Text Scaler',
              style: TextStyler()
                  .color($foreground())
                  .style($labelMedium.mix())
                  .wrap(.padding(.vertical(8))),
            ),
            Spacer(),
            StyledText(
              '${1.toStringAsFixed(1)}x',
              style: TextStyler()
                  .color($foreground())
                  .style($labelMedium.mix()),
            ),
          ],
        ),
        HeroSlider(
          min: 1,
          max: 2.0,
          value: 1,
          snapDivisions: 5,
          showOutput: false,
          onChanged: (value) {
            // context.read<SlideConfigurationStore>().textScaler = value;
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
        Spacer(),
        SizedBox(
          width: 48,
          child: HeroIconButton(
            icon: CupertinoIcons.share,
            size: .lg,
            variant: .secondary,
            onPressed: () {},
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
