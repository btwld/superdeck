import 'package:flutter/material.dart';
import 'package:hero_ui/hero_ui.dart';
import 'package:mix/mix.dart';

import 'customization_sidebar.dart';
import 'preview_sidebar.dart';
import 'text_editor.dart';
import 'thumbnail_refresher.dart';

class EditorPage extends StatelessWidget {
  const EditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ThumbnailRefresher(
      child: Scaffold(
        backgroundColor: $background.resolve(context),
        body: Box(
          style: BoxStyler().color($background()),
          child: RowBox(
            children: [
              PreviewSidebar(),
              Expanded(child: TextEditor()),
              CustomizationSidebar(),
            ],
          ),
        ),
      ),
    );
  }
}
