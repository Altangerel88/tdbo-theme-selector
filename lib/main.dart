import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme_sheet.dart';
import 'tokens.dart';

// `--dart-define=START=light|dark|system` picks the theme the app opens with.
const _start = String.fromEnvironment('START', defaultValue: 'system');

void main() => runApp(const TdboThemeApp());

class TdboThemeApp extends StatefulWidget {
  const TdboThemeApp({super.key});

  @override
  State<TdboThemeApp> createState() => _TdboThemeAppState();
}

class _TdboThemeAppState extends State<TdboThemeApp> {
  final _selection = ValueNotifier(
    AppTheme.values.firstWhere(
      (t) => t.name == _start,
      orElse: () => AppTheme.system,
    ),
  );

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _selection,
      builder: (context, theme, _) => MaterialApp(
        title: 'TDB Online',
        debugShowCheckedModeBanner: false,
        theme: tdboTheme(Brightness.light),
        darkTheme: tdboTheme(Brightness.dark),
        themeMode: theme.mode,
        themeAnimationDuration: const Duration(milliseconds: 350),
        themeAnimationCurve: Curves.easeInOut,
        home: SettingsScreen(selection: _selection),
      ),
    );
  }
}

/// A minimal Тохиргоо screen behind the sheet, so the chosen theme visibly
/// applies to the app. The sheet opens on launch.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.selection});

  final ValueNotifier<AppTheme> selection;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openSheet());
  }

  Future<void> _openSheet() async {
    final topInset = MediaQuery.paddingOf(context).top;
    setState(() => _sheetOpen = true);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => SizedBox.expand(
        child: ThemeSelectorSheet(
          selection: widget.selection,
          topInset: topInset,
        ),
      ),
    );
    if (mounted) setState(() => _sheetOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = TdboPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlay = (_sheetOpen || isDark)
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        backgroundColor: p.bg,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 20),
                child: Text(
                  'Тохиргоо',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: p.ink,
                  ),
                ),
              ),
              _Group(
                children: [
                  ValueListenableBuilder(
                    valueListenable: widget.selection,
                    builder: (context, theme, _) => _Row(
                      icon: Icons.contrast_rounded,
                      title: 'Харагдах байдал',
                      value: theme.label,
                      onTap: _openSheet,
                    ),
                  ),
                  const _Row(
                    icon: Icons.language_rounded,
                    title: 'Хэл',
                    value: 'Монгол',
                  ),
                  const _Row(
                    icon: Icons.notifications_none_rounded,
                    title: 'Мэдэгдэл',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = TdboPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 56, color: p.divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, this.value, this.onTap});

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = TdboPalette.of(context);
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: p.accent),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: p.ink,
                ),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: p.muted,
                ),
              ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 22, color: p.muted),
          ],
        ),
      ),
    );
  }
}
