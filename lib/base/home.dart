import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'color_screen.dart';
import 'tdbo_home.dart';
import 'theme_model.dart';

// `--dart-define=AUTO=drawer|screen` opens the flow on launch (for screenshots).
const _auto = String.fromEnvironment('AUTO');

/// The TDBO home; its avatar opens Base's side drawer, whose «Өнгө солих»
/// opens the full-screen picker. Saving applies the theme and shows a toast.
class BaseHome extends StatefulWidget {
  const BaseHome({super.key, required this.spec});

  final ValueNotifier<ThemeSpec> spec;

  @override
  State<BaseHome> createState() => _BaseHomeState();
}

class _BaseHomeState extends State<BaseHome> {
  final _scaffold = GlobalKey<ScaffoldState>();
  bool _balanceHidden = false;

  @override
  void initState() {
    super.initState();
    if (_auto.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _scaffold.currentState?.openDrawer();
        if (_auto == 'screen') {
          await Future<void>.delayed(const Duration(milliseconds: 450));
          if (mounted) _openColors(_scaffold.currentContext!);
        }
      });
    }
  }

  Future<void> _openColors(BuildContext context) async {
    final next = await openColorScreen(context, widget.spec.value);
    if (next == null || next == widget.spec.value || !mounted) return;
    widget.spec.value = next;
    if (context.mounted) _showToast(context);
  }

  @override
  Widget build(BuildContext context) {
    final look = Look.read(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: _scaffold,
        backgroundColor: look.surface,
        drawer: _MenuDrawer(onColors: _openColors),
        drawerScrimColor: Colors.black.withValues(alpha: 0.35),
        body: TdboHomeView(
          look: look,
          onAvatar: () => _scaffold.currentState?.openDrawer(),
          balanceHidden: _balanceHidden,
          onToggleBalance: () =>
              setState(() => _balanceHidden = !_balanceHidden),
        ),
      ),
    );
  }
}

void _showToast(BuildContext context) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => _Toast(onDone: () => entry.remove()));
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  const _Toast({required this.onDone});
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  @override
  void initState() {
    super.initState();
    _c.forward().then((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      if (!mounted) return;
      await _c.reverse();
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final look = Look.read(context);
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 10,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, -0.4),
              end: Offset.zero,
            ).animate(curve),
            child: Center(
              child: Material(
                color: look.surface,
                elevation: 6,
                shadowColor: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF28A745),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Өнгө солигдлоо',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: look.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Base's profile drawer: tinted header with the user and balance, then the
/// menu.
class _MenuDrawer extends StatelessWidget {
  const _MenuDrawer({required this.onColors});
  final Future<void> Function(BuildContext) onColors;

  @override
  Widget build(BuildContext context) {
    final look = Look.read(context);
    final top = MediaQuery.paddingOf(context).top;
    Widget item(IconData icon, String label, {VoidCallback? onTap}) => InkWell(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: look.ink),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: look.ink,
              ),
            ),
          ],
        ),
      ),
    );

    return Drawer(
      width: 300,
      backgroundColor: look.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            width: double.infinity,
            color: look.tint,
            padding: EdgeInsets.fromLTRB(20, top + 20, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: look.accent.withValues(
                      alpha: look.isDark ? 0.28 : 0.16,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 30,
                    color: readable(look.accent, look.tint),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Алтангэрэл',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: look.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '123,456,789.12',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: look.ink,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'MNT',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: look.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          item(Icons.person_add_alt_1_outlined, 'Найзаа урих'),
          item(Icons.person_outline_rounded, 'Профайл'),
          item(
            Icons.palette_outlined,
            'Өнгө солих',
            onTap: () => onColors(context),
          ),
          item(Icons.settings_outlined, 'Тохиргоо'),
          item(Icons.chat_bubble_outline_rounded, 'Санал хүсэлт'),
        ],
      ),
    );
  }
}
