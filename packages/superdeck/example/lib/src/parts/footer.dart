import 'package:flutter/material.dart';

class FooterPart extends StatelessWidget implements PreferredSizeWidget {
  const FooterPart({
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text('SUPERDECK'),
        ],
      ),
    );
  }
}
