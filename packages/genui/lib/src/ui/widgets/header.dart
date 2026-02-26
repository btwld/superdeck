import 'package:flutter/material.dart';
import 'package:remix/remix.dart';

/// Height of the header content area (excluding system padding).
const _kHeaderContentHeight = 60.0;

class SdHeader extends StatelessWidget implements PreferredSizeWidget {
  const SdHeader({super.key, this.leading, this.trailing});

  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final flex = FlexBoxStyler()
        .borderBottom(color: FortalTokens.gray3())
        .padding(.symmetric(horizontal: 24, vertical: 12))
        .height(_kHeaderContentHeight)
        .crossAxisAlignment(.center)
        .mainAxisAlignment(.spaceBetween);

    return SafeArea(
      bottom: false,
      child: flex(
        children: [
          SizedBox(child: leading),
          SizedBox(child: trailing),
        ],
      ),
    );
  }

  @override
  Size get preferredSize {
    // Content height only; Scaffold accounts for top system padding.
    return const Size.fromHeight(_kHeaderContentHeight);
  }
}
