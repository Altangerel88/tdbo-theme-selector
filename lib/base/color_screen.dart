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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: TweenAnimationBuilder<Look>(
                    tween: _LookTween(end: preview),
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                    builder: (context, l, _) => _PreviewBox(look: l),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
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
                            selected: m == _current.mode,
                            ring: look.accent,
                            look: look,
                            onTap: () => _set(_current.copyWith(mode: m)),
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
                                  selected: a == _current.accent,
                                  ring: look.accent,
                                  onTap: () =>
                                      _set(_current.copyWith(accent: a)),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
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

/// Base's tinted box with the phone peeking up from its bottom edge: the
/// draft colour washed into the draft mode's background, and the real home.
/// Base's tinted box: the TDB app icon as it would look on the home screen,
/// and below it the phone peeking up from the bottom edge with the dashboard
/// skeleton, both in the chosen Горим and Өнгө.
class _PreviewBox extends StatelessWidget {
  const _PreviewBox({required this.look});
  final Look look;

  static const _iconSize = 56.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const iconTop = 20.0;
        const top = iconTop + _iconSize + 18;
        // Show the phone from the status bar down to about the banner.
        const phone = TdboHomePreview.phone;
        // Sized as before the icon was added (from a 22px top), so the phone
        // keeps its size and simply runs further past the bottom edge.
        final byHeight =
            (c.maxHeight - 22) / (phone.height / phone.width * 0.66);
        final width = byHeight.clamp(120.0, c.maxWidth * 0.62);
        // The frame's 40px corners, scaled.
        final radius = 40 * width / phone.width;
        final shadow = BoxShadow(
          color: Colors.black.withValues(alpha: look.isDark ? 0.35 : 0.10),
          blurRadius: 24,
          offset: const Offset(0, 6),
        );

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
                top: iconTop,
                left: 0,
                right: 0,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      // The icon's own corner: 120 of 512.
                      borderRadius: BorderRadius.circular(
                        _iconSize * 120 / 512,
                      ),
                      boxShadow: [shadow],
                    ),
                    child: TdbAppIcon(look: look, size: _iconSize),
                  ),
                ),
              ),
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
                      boxShadow: [shadow],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(radius),
                      ),
                      child: TdboHomePreview(look: look, width: width),
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
