import 'package:flutter/material.dart';
import 'package:superdeck/src/modules/common/helpers/extensions.dart';

import '../../modules/common/helpers/provider.dart';
import '../../modules/deck/slide_configuration.dart';
import '../atoms/slide_view.dart';

class SlideScreen extends StatelessWidget {
  const SlideScreen(
    this.configuration, {
    super.key,
  });

  final SlideConfiguration configuration;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 29, 29, 29),
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
