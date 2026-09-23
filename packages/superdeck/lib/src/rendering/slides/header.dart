import 'package:flutter/widgets.dart';
import '../../deck/slide_configuration.dart';

class HeaderPart extends StatelessWidget implements PreferredSizeWidget {
  const HeaderPart({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(context) {
    final slide = SlideConfiguration.of(context);

    final index = slide.slideIndex;
    final title = slide.options.title;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (title != null) ...[Text(title), const SizedBox(width: 20)],
          Text('${index + 1}'),
        ],
      ),
    );
  }
}
