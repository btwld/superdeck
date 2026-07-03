import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:mix/mix.dart';

import '../widgets/customization_sidebar.dart';
import '../widgets/preview_sidebar.dart';
import '../widgets/text_editor.dart';

class EditorPage extends StatelessWidget {
  const EditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: $background.resolve(context),
      body: Box(
        style: BoxStyler().color($background()),
        child: RowBox(
          children: const [
            PreviewSidebar(),
            Expanded(child: TextEditor()),
            CustomizationSidebar(),
          ],
        ),
      ),
    );
  }
}
