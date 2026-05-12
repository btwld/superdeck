import 'package:flutter/cupertino.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:mix/mix.dart';

class SlidesSidebar extends StatelessWidget {
  const SlidesSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return StackBox(
      style: StackBoxStyler().minWidth(218).maxWidth(328).marginAll(16),
      children: [
        ColumnBox(
          style: FlexBoxStyler().spacing(24),
          children: [
            _Toolbar(),
            Expanded(child: _PreviewList()),
          ],
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
            variant: .secondary,
            onPressed: () {},
          ),
        ),
        SizedBox(
          width: 48,
          child: HeroIconButton(icon: CupertinoIcons.play, onPressed: () {}),
        ),
      ],
    );
  }
}

class _PreviewList extends StatelessWidget {
  const _PreviewList();

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollBehavior().copyWith(scrollbars: false),
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return Padding(
            padding: const .only(bottom: 24),
            child: _PreviewItem(index: index),
          );
        },
      ),
    );
  }
}

class _PreviewItem extends StatelessWidget {
  const _PreviewItem({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: .bottomRight,
      children: [
        Box(
          style: BoxStyler()
              .color($accent())
              .borderRadiusAll($radius())
              .wrap(.aspectRatio(2)),
        ),
        StyledText(
          '${index + 1}',
          style: TextStyler()
              .style(TextStyleMix(color: $white()))
              .wrap(
                .box(
                  BoxStyler()
                      .shapeStadium()
                      .padding(.horizontal(10).vertical(2))
                      .color($backdrop())
                      .marginAll(8),
                ),
              ),
        ),
      ],
    );
  }
}
