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
                child: TweenAnimationBuilder<Look>(
                  tween: _LookTween(end: preview),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                  builder: (context, l, _) => LayoutBuilder(
                    builder: (context, c) {
                      // Icon block: 4 above, 60 icon, 16 below; caption 32.
                      const iconBlock = 80.0, caption = 32.0;
                      // The card takes 85% of the height left after the icon
                      // and caption, with wide side margins; all of it sits
                      // centred in the space.
                      final boxHeight =
                          (c.maxHeight - iconBlock - caption) * 0.85;
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
                              child: _BackdropFan(
                                look: l,
                                selected: _current.backdrop,
                                onSelect: (b) =>
                                    _set(_current.copyWith(backdrop: b)),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: caption,
                            child: Center(
                              child: Text(
                                _current.backdrop.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: l.muted,
                                ),
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

/// Дэвсгэр: a fan of preview cards, one per [Backdrop], in the chosen Горим
/// and Өнгө. The centre card is the choice; its neighbours sit smaller and
/// lower behind it. Swipe, or tap a side card, to bring it to the centre.
///
/// A transparent [PageView] on top does the dragging and snapping; the cards
/// are drawn underneath from its position, sorted so the centre one is in
/// front. Cards are taller than the box and clipped at its bottom edge.
class _BackdropFan extends StatefulWidget {
  const _BackdropFan({
    required this.look,
    required this.selected,
    required this.onSelect,
  });

  final Look look;
  final Backdrop selected;
  final ValueChanged<Backdrop> onSelect;

  @override
  State<_BackdropFan> createState() => _BackdropFanState();
}

class _BackdropFanState extends State<_BackdropFan> {
  static const _slot = 0.27; // page width, as a share of the box
  static const _card = 0.52; // centre card width, as a share of the box

  late final _pages = PageController(
    viewportFraction: _slot,
    initialPage: widget.selected.index,
  );

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final look = widget.look;
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cardW = w * _card;
        final radius = 40 * cardW / TdboHomePreview.phone.width;
        final cards = [
          for (final b in Backdrop.values)
            RepaintBoundary(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: look.isDark ? 0.40 : 0.14,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: TdboHomePreview(look: look, width: cardW, backdrop: b),
                ),
              ),
            ),
        ];

        return Container(
          decoration: BoxDecoration(
            color: look.tint,
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _pages,
                builder: (context, _) {
                  final page =
                      _pages.hasClients && _pages.position.haveDimensions
                      ? _pages.page!
                      : widget.selected.index.toDouble();
                  final order = [for (var i = 0; i < cards.length; i++) i]
                    ..sort(
                      (a, b) => (b - page).abs().compareTo((a - page).abs()),
                    );
                  return Stack(
                    children: [
                      for (final i in order)
                        _place(i, page, w, cardW, cards[i]),
                    ],
                  );
                },
              ),
              PageView.builder(
                controller: _pages,
                itemCount: cards.length,
                onPageChanged: (i) => widget.onSelect(Backdrop.values[i]),
                itemBuilder: (context, i) => Semantics(
                  button: true,
                  selected: i == widget.selected.index,
                  label: '${Backdrop.values[i].label} дэвсгэр',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _pages.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 360),
                      curve: Curves.easeOutCubic,
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

  Widget _place(int i, double page, double w, double cardW, Widget card) {
    final d = i - page;
    final far = d.abs().clamp(0.0, 2.0);
    return Positioned(
      key: ValueKey(i),
      left: w / 2 - cardW / 2 + d * w * _slot,
      top: 22 + 16 * far,
      child: Opacity(
        opacity: (1 - (d.abs() - 1.6).clamp(0.0, 1.0)).toDouble(),
        child: Transform.scale(
          scale: 1 - 0.15 * far,
          alignment: Alignment.topCenter,
          child: card,
        ),
      ),
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
