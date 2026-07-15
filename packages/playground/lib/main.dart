import 'package:flutter/material.dart';

import 'package:hero_ui/hero_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'app/providers.dart';
import 'app/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Silence signals' verbose debug logging (enabled by default in debug mode).
  SignalsObserver.instance = null;

  // debugRepaintRainbowEnabled = true;
  runApp(const SuperdeckApp());
}

class SuperdeckApp extends StatefulWidget {
  const SuperdeckApp({super.key});

  @override
  State<SuperdeckApp> createState() => _SuperdeckAppState();
}

class _SuperdeckAppState extends State<SuperdeckApp> {
  final _router = createRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Superdeck',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      builder: (context, child) => _Theme(child: AppProviders(child: child!)),
    );
  }
}

class _Theme extends StatelessWidget {
  const _Theme({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return HeroTheme(
      data: MediaQuery.of(context).platformBrightness == Brightness.dark
          ? .dark()
          : .light(),
      child: child,
    );
  }
}
