import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tdbo_home.dart';
import 'theme_model.dart';

/// Resolves Систем against the phone's brightness.
ModeChoice resolveMode(ModeChoice mode, Brightness platform) =>
    mode == ModeChoice.system
    ? (platform == Brightness.dark ? ModeChoice.khar : ModeChoice.tsagaan)
    : mode;

/// Opens «Өнгө солих» full screen; completes with the saved [ThemeSpec], or
/// null on back.
Future<ThemeSpec?> openColorScreen(BuildContext context, ThemeSpec current) =>
    Navigator.of(context).push<ThemeSpec>(
      MaterialPageRoute(builder: (_) => ColorScreen(initial: current)),
    );

/// Base's theme flow as a full screen: the real TDBO home previews the draft
/// above Горим and Өнгө, and the Хадгалах button wears the draft colour.
/// Nothing applies until Хадгалах.
class ColorScreen extends StatefulWidget {
  const ColorScreen({super.key, required this.initial});

  final ThemeSpec initial;

  @override
  State<ColorScreen> createState() => _ColorScreenState();
}

class _ColorScreenState extends State<ColorScreen> {
  late ThemeSpec _draft = widget.initial;

  void _set(ThemeSpec next) {
    if (next == _draft) return;
    HapticFeedback.selectionClick();
    setState(() => _draft = next);
  }

  @override
  Widget build(BuildContext context) {
    final look = Look.read(context);
    final platform = MediaQuery.platformBrightnessOf(context);
    // The screen keeps the app's current surface; only the accent follows
    // the draft, tuned for that surface.
    final screenMode = look.isDark
        ? (resolveMode(widget.initial.mode, platform) == ModeChoice.baraan
              ? ModeChoice.baraan
              : ModeChoice.khar)
        : ModeChoice.tsagaan;
    final accent = Look.of(screenMode, _draft.accent);
    final preview = Look.of(resolveMode(_draft.mode, platform), _draft.accent);
    final changed = _draft != widget.initial;

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
                        onPressed: () => Navigator.of(context).pop(),
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
                            dot: m == ModeChoice.baraan
                                ? const Color(0xFF4A90FF)
                                : _draft.accent.color,
                            selected: m == _draft.mode,
                            ring: accent.accent,
                            look: look,
                            onTap: () => _set(_draft.copyWith(mode: m)),
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
                                  selected: a == _draft.accent,
                                  ring: accent.accent,
                                  onTap: () => _set(_draft.copyWith(accent: a)),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SaveButton(
                      look: accent,
                      enabled: changed,
                      onPressed: () => Navigator.of(context).pop(_draft),
                    ),
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
class _PreviewBox extends StatelessWidget {
  const _PreviewBox({required this.look});
  final Look look;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const top = 22.0;
        // Show the phone from the status bar down to about the banner.
        const phone = TdboHomePreview.phone;
        final byHeight =
            (c.maxHeight - top) / (phone.height / phone.width * 0.66);
        final width = byHeight.clamp(120.0, c.maxWidth * 0.62);
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
    required this.dot,
    required this.selected,
    required this.ring,
    required this.look,
    required this.onTap,
  });

  final ModeChoice mode;
  final Color dot;
  final bool selected;
  final Color ring;
  final Look look;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (fill, border) = switch (mode) {
      ModeChoice.tsagaan => (const Color(0xFFF5F9F8), const Color(0xFFDDE6E3)),
      ModeChoice.khar => (const Color(0xFF121212), const Color(0xFF121212)),
      ModeChoice.system => (const Color(0xFFEFF5F3), const Color(0xFFDDE6E3)),
      ModeChoice.baraan => (const Color(0xFF0B0D12), const Color(0xFF0B0D12)),
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
              _Ring(
                selected: selected,
                color: ring,
                size: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: fill,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: look.isDark && border == fill
                          ? look.divider
                          : border,
                    ),
                  ),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: dot,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                mode.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? look.ink : look.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.look,
    required this.enabled,
    required this.onPressed,
  });

  final Look look;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: enabled,
    child: GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 52,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: look.accent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: enabled ? 1 : 0.5,
          child: Text(
            'Хадгалах',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: look.onAccent,
            ),
          ),
        ),
      ),
    ),
  );
}
