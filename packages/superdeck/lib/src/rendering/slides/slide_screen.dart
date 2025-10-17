import 'package:flutter/material.dart';
import 'package:superdeck/src/utils/extensions.dart';

import '../../deck/slide_configuration.dart';
import '../../ui/widgets/provider.dart';
import 'slide_view.dart';

class SlideScreen extends StatelessWidget {
  const SlideScreen(this.configuration, {super.key});

  final SlideConfiguration configuration;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.useOpacity(0.3),
              blurRadius: 6,
              spreadRadius: 3,
            ),
          ],
        ),
        child: InheritedData(
          data: configuration,
          child: SlideView(configuration),
        ),
      ),
    );
  }
}
