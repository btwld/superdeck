import 'package:flutter/material.dart';
import 'package:mix/mix.dart';

class CommentsPanel extends StatelessWidget {
  const CommentsPanel({
    super.key,
    required this.comments,
  });

  final List<String> comments;

  @override
  Widget build(BuildContext context) {
    final boxStyle = Style(
      $box.color(const Color.fromARGB(255, 35, 35, 35)),
      $box.margin.only(top: 10, left: 10, right: 10, bottom: 0),
      $box.borderRadius(10),
    );

    final flexStyle = Style(
      $flex.crossAxisAlignment.stretch(),
      $flex.gap(10),
      $box.padding(10),
    );
    return Box(
      style: boxStyle,
      child: SingleChildScrollView(
        child: VBox(
          style: flexStyle,
          children: comments.map(Text.new).toList(),
        ),
      ),
    );
  }
}
