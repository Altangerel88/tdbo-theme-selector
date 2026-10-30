import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'base/color_screen.dart';
import 'base/tdbo_home.dart';
import 'base/theme_model.dart';

// The theme picker as a bottom sheet over the TDBO home:
// `flutter run -t lib/main_sheet.dart`. The sheet opens on launch; tap the
// home to open it again. Choices re-theme the home behind it live.
void main() => runApp(const SheetApp());

class SheetApp extends StatefulWidget {
  const SheetApp({super.key});

  @override
  State<SheetApp> createState() => _SheetAppState();
}

class _SheetAppState extends State<SheetApp> {
  final _spec = ValueNotifier(
    const ThemeSpec(ModeChoice.tsagaan, Accent.green),
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
        home: _Home(spec: _spec),
      ),
    );
  }
}

class _Home extends StatefulWidget {
  const _Home({required this.spec});
  final ValueNotifier<ThemeSpec> spec;

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final a in Accent.values) {
      precacheImage(AssetImage(a.photo), context);
    }
  }

  void _open() => showThemeSheet(context, widget.spec);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _open,
          child: TdboHomeView(
            look: Look.read(context),
            accent: widget.spec.value.accent,
            onAvatar: _open,
          ),
        ),
      ),
    );
  }
}
