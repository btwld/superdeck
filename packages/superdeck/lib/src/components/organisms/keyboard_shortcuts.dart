import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:superdeck/src/modules/navigation/navigation_controller.dart';

class NextSlideIntent extends Intent {}

class PreviousSlideIntent extends Intent {}

// Define your actions:
class NextSlideAction extends Action<NextSlideIntent> {
  final NavigationController navigation;
  NextSlideAction({required this.navigation});

  @override
  Object? invoke(covariant NextSlideIntent intent) {
    navigation.nextSlide();
    return null;
  }
}

class PreviousSlideAction extends Action<PreviousSlideIntent> {
  final NavigationController navigation;
  PreviousSlideAction({required this.navigation});

  @override
  Object? invoke(covariant PreviousSlideIntent intent) {
    navigation.previousSlide();
    return null;
  }
}

class KeyboardShortcuts extends StatelessWidget {
  const KeyboardShortcuts({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final navigation = NavigationController.of(context);
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        // Using a LogicalKeySet allows you to define multiple keys.
        LogicalKeySet(LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.meta):
            NextSlideIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.meta):
            NextSlideIntent(),
        LogicalKeySet(LogicalKeyboardKey.space, LogicalKeyboardKey.meta):
            NextSlideIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.meta):
            PreviousSlideIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.meta):
            PreviousSlideIntent(),
      },
      child: Actions(actions: <Type, Action<Intent>>{
        NextSlideIntent: NextSlideAction(
          navigation: navigation,
        ),
        PreviousSlideIntent: PreviousSlideAction(
          navigation: navigation,
        ),
      }, child: child),
    );
  }
}
