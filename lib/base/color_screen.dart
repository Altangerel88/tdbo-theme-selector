import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tdb_icon.dart';
import 'tdbo_home.dart';
import 'theme_model.dart';

/// Resolves Систем against the phone's brightness.
ModeChoice resolveMode(ModeChoice mode, Brightness platform) =>
    mode == ModeChoice.system
    ? (platform == Brightness.dark ? ModeChoice.khar : ModeChoice.tsagaan)
    : mode;

/// Base's theme flow as a full screen: a skeleton TDBO home previews the
/// choice above Горим and Өнгө. There is no save step — each tap applies the
/// theme to the whole app at once.
class ColorScreen extends StatefulWidget {
  const ColorScreen({super.key, required this.spec});

  final ValueNotifier<ThemeSpec> spec;

  @override
  State<ColorScreen> createState() => _ColorScreenState();
}

class _ColorScreenState extends State<ColorScreen> {
  ThemeSpec get _current => widget.spec.value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decode every header photo up front, so switching colour never flashes.
    for (final a in Accent.values) {
      precacheImage(AssetImage(a.photo), context);
    }
  }

  void _set(ThemeSpec next) {
    if (next == _current) return;
    HapticFeedback.selectionClick();
    setState(() => widget.spec.value = next);
  }

  @override
  Widget build(BuildContext context) {
    final look = Look.read(context);
    final platform = MediaQuery.platformBrightnessOf(context);
    final preview = Look.of(
      resolveMode(_current.mode, platform),
      _current.accent,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: look.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: look.bg,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 56,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 8,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        tooltip: 'Буцах',
                        icon: Icon(Icons.arrow_back_rounded, color: look.ink),
                      ),
                    ),
                    Text(
                      'Өнгө солих',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: look.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TweenAnimationBuilder<Look>(
                  tween: _LookTween(end: preview),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                  builder: (context, l, _) => LayoutBuilder(
                    builder: (context, c) {
                      // Icon block: 4 above, 60 icon, 16 below.
                      const iconBlock = 80.0;
                      // The card takes 85% of the height left after the icon,
                      // with wide side margins; icon and card sit centred in
                      // the space.
                      final boxHeight = (c.maxHeight - iconBlock) * 0.85;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // The TDB app icon as it would look on the home
                          // screen, on the page above the preview.
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
                            child: _AppIcon(look: l),
                          ),
                          SizedBox(
                            height: boxHeight,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 36,
                              ),
                              // Each colour's own header photo, in every
                              // Горим.
                              child: _PreviewBox(
                                look: l,
                                accent: _current.accent,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Pickers(current: _current, look: look, onChanged: _set),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Горим and Өнгө, shared by the full-screen page and the bottom sheet.
class _Pickers extends StatelessWidget {
  const _Pickers({
    required this.current,
    required this.look,
    required this.onChanged,
  });

  final ThemeSpec current;
  final Look look;
  final ValueChanged<ThemeSpec> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('Горим', look),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final m in ModeChoice.values)
              _ModeTile(
                mode: m,
                selected: m == current.mode,
                ring: look.accent,
                look: look,
                onTap: () => onChanged(current.copyWith(mode: m)),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _Label('Өнгө', look),
        const SizedBox(height: 10),
        // Inset 8px so the circles centre under the 68-wide mode tiles.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: LayoutBuilder(
            builder: (context, c) {
              const perRow = 4;
              const d = 52.0;
              final gap = (c.maxWidth - perRow * d) / (perRow - 1);
              return Wrap(
                spacing: gap,
                runSpacing: 14,
                children: [
                  for (final a in Accent.values)
                    _Swatch(
                      color: a.color,
                      size: d,
                      selected: a == current.accent,
                      ring: look.accent,
                      onTap: () => onChanged(current.copyWith(accent: a)),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The picker as the TDBO 2.0 bottom sheet (Figma 7jLPHUpWV7s9UK49iIbVhR,
/// «Bottom Sheet / Theme selector» 312:102): white, top corners 18, padding
/// 32/32/42/32, gap 20 — title, app icon, a 280-high preview card, Горим and
/// Өнгө. Like the page, each tap applies at once.
Future<void> showThemeSheet(
  BuildContext context,
  ValueNotifier<ThemeSpec> spec,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  // The Figma previews' overlay: black at 60%.
  barrierColor: Colors.black.withValues(alpha: 0.6),
  builder: (_) => ThemeSheet(spec: spec),
);

class ThemeSheet extends StatefulWidget {
  const ThemeSheet({super.key, required this.spec});

  final ValueNotifier<ThemeSpec> spec;

  @override
  State<ThemeSheet> createState() => _ThemeSheetState();
}

class _ThemeSheetState extends State<ThemeSheet> {
  ThemeSpec get _current => widget.spec.value;

  void _set(ThemeSpec next) {
    if (next == _current) return;
    HapticFeedback.selectionClick();
    setState(() => widget.spec.value = next);
  }

  @override
  Widget build(BuildContext context) {
    final look = Look.read(context);
    final platform = MediaQuery.platformBrightnessOf(context);
    final preview = Look.of(
      resolveMode(_current.mode, platform),
      _current.accent,
    );
    return Container(
      decoration: BoxDecoration(
        color: look.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 42),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The sheet's title style: Manrope Bold 24, #424242.
          Text(
            'Өнгө солих',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.6,
              color: look.isDark ? look.ink : const Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 20),
          TweenAnimationBuilder<Look>(
            tween: _LookTween(end: preview),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            builder: (context, l, _) => Column(
              children: [
                Center(child: _AppIcon(look: l)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 280,
                  child: _PreviewBox(look: l, accent: _current.accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Pickers(current: _current, look: look, onChanged: _set),
        ],
      ),
    );
  }
}

/// The TDB app icon with the soft shadow it has on a home screen.
class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.look});
  final Look look;

  static const _size = 60.0;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      // The icon's own corner: 120 of 512.
      borderRadius: BorderRadius.circular(_size * 120 / 512),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: look.isDark ? 0.35 : 0.12),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: TdbAppIcon(look: look, size: _size),
  );
}

/// Base's tinted box with the phone peeking up from its bottom edge: the
/// dashboard skeleton in the chosen Горим and Өнгө.
class _PreviewBox extends StatelessWidget {
  const _PreviewBox({required this.look, required this.accent});
  final Look look;
  final Accent accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const top = 22.0;
        const phone = TdboHomePreview.phone;
        // A fixed share of the width; the box's height only decides how much
        // of the phone shows.
        final width = c.maxWidth * 0.62;
        // The frame's 40px corners, scaled.
        final radius = 40 * width / phone.width;

        // The phone is taller than the box on purpose: it runs past the
        // bottom edge and is clipped there. A Positioned child gets unbounded
        // height, so the preview keeps its full size instead of shrinking to
        // fit (which left gaps beside it).
        return Container(
          decoration: BoxDecoration(
            color: look.tint,
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                top: top,
                left: 0,
                right: 0,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(radius),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: look.isDark ? 0.35 : 0.10,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(radius),
                      ),
                      child: TdboHomePreview(
                        look: look,
                        width: width,
                        accent: accent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, this.look);
  final String text;
  final Look look;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: look.muted,
    ),
  );
}

class _LookTween extends Tween<Look> {
  _LookTween({required Look end}) : super(begin: end, end: end);

  @override
  Look lerp(double t) => begin!.lerp(end, t);
}

/// The mode icon from the current screen: the mode's background with an
/// accent dot (Бараан keeps its blue dot).
class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.mode,
    required this.selected,
    required this.ring,
    required this.look,
    required this.onTap,
  });

  final ModeChoice mode;
  final bool selected;
  final Color ring;
  final Look look;
  final VoidCallback onTap;

  // Revolut's swatches: soft top-left to bottom-right gradients.
  static const _light = [Color(0xFFF0F0F0), Color(0xFFDADADA)];
  static const _black = [Color(0xFF4A4A4A), Color(0xFF1E1E1E)];
  static const _navy = [Color(0xFF2A3A5E), Color(0xFF0B1222)];

  static Widget _disc(List<Color> colors, {Color? rim}) => DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
      border: rim == null ? null : Border.all(color: rim),
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Light discs get a hairline so they hold their edge on a light page.
    final lightRim = look.isDark ? null : const Color(0xFFD4D4D4);
    final fill = switch (mode) {
      ModeChoice.tsagaan => _disc(_light, rim: lightRim),
      ModeChoice.khar => _disc(_black),
      ModeChoice.baraan => _disc(_navy),
      ModeChoice.system => ClipOval(
        child: Row(
          children: [
            Expanded(child: _halfFill(_black)),
            Expanded(child: _halfFill(_light)),
          ],
        ),
      ),
    };
    return Semantics(
      button: true,
      selected: selected,
      label: '${mode.label} горим',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 68,
          child: Column(
            children: [
              _Ring(selected: selected, color: ring, size: 52, child: fill),
              const SizedBox(height: 8),
              Text(
                mode.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? look.ink : look.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _halfFill(List<Color> colors) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ),
    ),
    child: const SizedBox.expand(),
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.size,
    required this.selected,
    required this.ring,
    required this.onTap,
  });

  final Color color;
  final double size;
  final bool selected;
  final Color ring;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: 'Өнгө',
    child: GestureDetector(
      onTap: onTap,
      child: _Ring(
        selected: selected,
        color: ring,
        size: size,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    ),
  );
}

/// Base's selection mark: a ring with a gap around the circle.
class _Ring extends StatelessWidget {
  const _Ring({
    required this.selected,
    required this.color,
    required this.size,
    required this.child,
  });

  final bool selected;
  final Color color;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    width: size,
    height: size,
    padding: EdgeInsets.all(selected ? 5 : 0),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: selected ? color : Colors.transparent,
        width: 2.5,
      ),
    ),
    child: child,
  );
}
