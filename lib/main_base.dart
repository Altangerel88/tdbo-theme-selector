import 'package:flutter/material.dart';

import 'base/color_screen.dart';
import 'base/theme_model.dart';

// «Өнгө солих» page on its own: `flutter run -t lib/main_base.dart`.
// `--dart-define=MODE=tsagaan|khar|system|baraan` and `ACCENT=green|blue|…`
// set the starting theme (default: Цагаан + green, as on the current screen).
const _mode = String.fromEnvironment('MODE', defaultValue: 'tsagaan');
const _accent = String.fromEnvironment('ACCENT', defaultValue: 'green');

void main() => runApp(const BaseFlowApp());

class BaseFlowApp extends StatefulWidget {
  const BaseFlowApp({super.key});

  @override
  State<BaseFlowApp> createState() => _BaseFlowAppState();
}

class _BaseFlowAppState extends State<BaseFlowApp> {
  final _spec = ValueNotifier(
    ThemeSpec(
      ModeChoice.values.firstWhere(
        (m) => m.name == _mode,
        orElse: () => ModeChoice.tsagaan,
      ),
      Accent.values.firstWhere(
        (a) => a.name == _accent,
        orElse: () => Accent.green,
      ),
    ),
  );

  @override
  void dispose() {
    _spec.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _spec,
      builder: (context, spec, _) => MaterialApp(
        title: 'TDB Online',
        debugShowCheckedModeBanner: false,
        theme: lookTheme(Look.of(ModeChoice.tsagaan, spec.accent)),
        darkTheme: lookTheme(
          Look.of(
            spec.mode == ModeChoice.baraan
                ? ModeChoice.baraan
                : ModeChoice.khar,
            spec.accent,
          ),
        ),
        themeMode: switch (spec.mode) {
          ModeChoice.tsagaan => ThemeMode.light,
          ModeChoice.khar || ModeChoice.baraan => ThemeMode.dark,
          ModeChoice.system => ThemeMode.system,
        },
        themeAnimationDuration: const Duration(milliseconds: 350),
        home: ColorScreen(spec: _spec),
      ),
    );
  }
}
