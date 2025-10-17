import 'package:flutter/material.dart';

class CommentsPanel extends StatelessWidget {
  const CommentsPanel({
    super.key,
    required this.comments,
  });

  final List<String> comments;

  @override
  Widget build(BuildContext context) {
    // Using Flutter widgets directly since this is a simple UI component
    return Container(
      margin: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 0),
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 35, 35, 35),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < comments.length; i++) ...[
              Text(comments[i]),
              if (i < comments.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
