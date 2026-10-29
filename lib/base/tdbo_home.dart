import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'header_logo_v8.dart';
import 'theme_model.dart';

/// The TDBO 2.0 retail home (Figma FVPs4KhiqJbNNbAsqIDBn6, «Retail» 74361:5083,
/// 425×912), recoloured from a [Look]: the header is built from the chosen
/// colour, and the quick-action plates, «Хуулга» link and active nav disc use
/// it. Full-size it is the home; with [skeleton] every text becomes a bar the
/// width of that text, for the picker's preview.
class TdboHomeView extends StatelessWidget {
  const TdboHomeView({
    super.key,
    required this.look,
    this.onAvatar,
    this.balanceHidden = false,
    this.onToggleBalance,
    this.preview = false,
  });

  final Look look;
  final VoidCallback? onAvatar;
  final bool balanceHidden;
  final VoidCallback? onToggleBalance;

  /// Skeleton text, a skeleton banner and a 9:41 status bar.
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final top = preview ? 44.0 : MediaQuery.paddingOf(context).top;
    return _Skeleton(
      on: preview,
      child: ColoredBox(
        color: look.surface,
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Runs 28px under the sheet so its rounded corners show it.
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: -28,
                        child: look.isDark
                            // Dark modes: the v8 logo thread from
                            // ~/tdbo_retail_home, in the chosen colour on the
                            // mode's background with a wash of that colour.
                            ? HeaderLogoV8(
                                underlap: 28,
                                line: look.accent,
                                ground: Color.alphaBlend(
                                  look.brand.withValues(alpha: 0.12),
                                  look.bg,
                                ),
                              )
                            : CustomPaint(
                                painter: _HeaderBg(look, streaks: !preview),
                              ),
                      ),
                      _Header(
                        look: look,
                        topInset: top,
                        balanceHidden: balanceHidden,
                        onAvatar: onAvatar,
                        onToggleBalance: onToggleBalance,
                      ),
                    ],
                  ),
                  Expanded(child: _Content(look: look)),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(child: _NavBar(look: look)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton text
// ---------------------------------------------------------------------------

class _Skeleton extends InheritedWidget {
  const _Skeleton({required this.on, required super.child});
  final bool on;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Skeleton>()?.on ?? false;

  @override
  bool updateShouldNotify(_Skeleton old) => old.on != on;
}

/// A [Text] that, inside a skeleton, draws a rounded bar as wide as the text
/// would be and centred in its line box. [bar] overrides the colour, which
/// otherwise is the text colour faded (16% for dark text, 45% for light).
class _Txt extends StatelessWidget {
  const _Txt(
    this.text,
    this.style, {
    this.bar,
    this.clamp = false,
    this.drop = false,
  });

  final String text;
  final TextStyle style;
  final Color? bar;

  /// Single line, ellipsised: the bar never exceeds the available width.
  final bool clamp;

  /// Left out of the skeleton altogether, to keep the preview sparse.
  final bool drop;

  @override
  Widget build(BuildContext context) {
    if (!_Skeleton.of(context)) {
      return Text(
        text,
        style: style,
        maxLines: clamp ? 1 : null,
        softWrap: !clamp,
        overflow: clamp ? TextOverflow.ellipsis : null,
      );
    }
    if (drop) return const SizedBox.shrink();
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textScaler: TextScaler.noScaling,
    )..layout();
    final c = style.color ?? Colors.black;
    final color =
        bar ??
        c.withValues(alpha: c.a * (c.computeLuminance() > 0.5 ? 0.45 : 0.16));
    final h = (style.fontSize ?? 14) * 0.6;

    Widget box(double w) => SizedBox(
      width: w,
      height: painter.height,
      child: Center(
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(h / 2),
          ),
        ),
      ),
    );
    if (!clamp) return box(painter.width);
    return LayoutBuilder(
      builder: (context, k) => box(painter.width.clamp(0, k.maxWidth)),
    );
  }
}

TextStyle _mr(
  double size,
  FontWeight weight,
  Color color, {
  double? height,
  double? ls,
}) => TextStyle(
  fontFamily: 'Manrope',
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
  letterSpacing: ls,
);

// ---------------------------------------------------------------------------
// Header (74361:5090)
// ---------------------------------------------------------------------------

/// Header ground: the chosen colour taken most of the way to near-black, with
/// the TDBO diagonal light streaks on the right.
class _HeaderBg extends CustomPainter {
  _HeaderBg(this.look, {this.streaks = true});
  final Look look;
  final bool streaks;

  @override
  void paint(Canvas canvas, Size size) {
    final night = look.isDark
        ? const Color(0xFF030507)
        : const Color(0xFF00040C);
    final depth = look.isDark ? 0.84 : 0.76;
    final base = Color.lerp(look.brand, night, depth)!;
    final lift = Color.lerp(look.brand, night, depth - 0.1)!;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lift, base, base, lift],
          stops: const [0, 0.35, 0.7, 1],
        ).createShader(rect),
    );
    if (!streaks) return;
    final streak = Color.lerp(look.brand, Colors.white, 0.25)!;
    canvas.save();
    canvas.clipRect(rect);
    final w = size.width, h = size.height;
    for (final (x, width, alpha) in const [
      (0.55, 0.10, 0.07),
      (0.72, 0.05, 0.10),
      (0.84, 0.14, 0.06),
      (1.02, 0.04, 0.12),
    ]) {
      final path = Path()
        ..moveTo(w * x, h)
        ..lineTo(w * (x + width), h)
        ..lineTo(w * (x + width + 0.45), 0)
        ..lineTo(w * (x + 0.45), 0)
        ..close();
      canvas.drawPath(path, Paint()..color = streak.withValues(alpha: alpha));
    }
    for (final x in const [0.62, 0.9]) {
      canvas.drawLine(
        Offset(w * x, h),
        Offset(w * (x + 0.45), 0),
        Paint()
          ..color = streak.withValues(alpha: 0.22)
          ..strokeWidth = 1,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HeaderBg old) =>
      old.look != look || old.streaks != streaks;
}

class _Icon extends StatelessWidget {
  const _Icon(this.name, {required this.size, this.color});
  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => _Skeleton.of(context)
      ? const SizedBox.shrink()
      : SvgPicture.asset(
          'assets/icons/$name.svg',
          width: size,
          height: size,
          colorFilter: color == null
              ? null
              : ColorFilter.mode(color!, BlendMode.srcIn),
        );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.look,
    required this.topInset,
    required this.balanceHidden,
    this.onAvatar,
    this.onToggleBalance,
  });

  final Look look;
  final double topInset;
  final bool balanceHidden;
  final VoidCallback? onAvatar;
  final VoidCallback? onToggleBalance;

  @override
  Widget build(BuildContext context) {
    final white72 = Colors.white.withValues(alpha: 0.72);
    final strong = Colors.white.withValues(alpha: 0.82);
    final skeleton = _Skeleton.of(context);
    final pillText = readable(look.brand, Colors.white);

    return Padding(
      // Figma: 56 top = 44 status bar + 12.
      padding: EdgeInsets.fromLTRB(24, topInset + 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Disc(
                size: 46,
                alpha: 0.14,
                onTap: onAvatar,
                child: const _Icon('user', size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Txt(
                      'Өдрийн мэнд!',
                      _mr(13, FontWeight.w500, white72),
                      drop: true,
                    ),
                    if (!skeleton) const SizedBox(height: 2),
                    _Txt(
                      'Алтангэрэл',
                      _mr(18, FontWeight.w800, Colors.white),
                      bar: strong,
                      clamp: true,
                    ),
                  ],
                ),
              ),
              _Disc(
                size: 42,
                alpha: 0.10,
                onTap: onToggleBalance,
                child: const _Icon('eye', size: 22),
              ),
              const SizedBox(width: 12),
              const _Disc(
                size: 42,
                alpha: 0.10,
                child: _Icon('bell', size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!skeleton) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Txt(
                    'MN91 0004 0040 0238 9817',
                    _mr(13, FontWeight.w500, white72),
                  ),
                  const SizedBox(width: 8),
                  const _Icon('copy', size: 16),
                ],
              ),
            ),
            const SizedBox(height: 3),
          ],
          Row(
            crossAxisAlignment: skeleton
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              _Txt(
                balanceHidden ? '••• ••• •••.••' : '123,456,789.12',
                _mr(24, FontWeight.w700, Colors.white),
                bar: strong,
              ),
              const SizedBox(width: 7),
              _Txt(
                'MNT',
                _mr(16, FontWeight.w700, Colors.white.withValues(alpha: 0.7)),
                drop: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Pill(
                'Дансны хуулга',
                fill: Colors.white,
                text: pillText,
                // Empty in the skeleton: the pill's shape is enough.
                bar: skeleton ? Colors.transparent : pillText,
              ),
              const SizedBox(width: 10),
              _Pill(
                'Данс хайх',
                fill: Colors.white.withValues(alpha: 0.10),
                text: Colors.white.withValues(alpha: 0.95),
                bar: skeleton ? Colors.transparent : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({
    required this.size,
    required this.alpha,
    required this.child,
    this.onTap,
  });
  final double size;
  final double alpha;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: alpha),
        shape: BoxShape.circle,
      ),
      child: child,
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, {required this.fill, required this.text, this.bar});
  final String label;
  final Color fill;
  final Color text;
  final Color? bar;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(22),
    ),
    child: _Txt(label, _mr(14, FontWeight.w600, text), bar: bar),
  );
}

// ---------------------------------------------------------------------------
// Content card (74361:5128)
// ---------------------------------------------------------------------------

class _Content extends StatelessWidget {
  const _Content({required this.look});
  final Look look;

  static const _green = Color(0xFF28A745);

  @override
  Widget build(BuildContext context) {
    final skeleton = _Skeleton.of(context);
    final plate = Color.alphaBlend(
      look.accent.withValues(alpha: look.isDark ? 0.18 : 0.09),
      look.surface,
    );
    final icon = readable(
      look.isDark ? look.accent : look.brand,
      plate,
      ratio: 3,
    );
    final link = readable(look.accent, look.surface);
    final block = Color.alphaBlend(
      look.ink.withValues(alpha: look.isDark ? 0.08 : 0.06),
      look.surface,
    );
    const lh = 22 / 14;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: ColoredBox(
        color: look.surface,
        child: ListView(
          // Bottom: 24 + nav 68 + 24 so the last row can scroll clear of the nav.
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 116),
          physics: const ClampingScrollPhysics(),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (name, size, label) in const [
                  ('qa_account', 20.0, 'Данс'),
                  ('qa_loan', 24.0, 'Зээл'),
                  ('qa_card', 24.0, 'Карт'),
                  ('qa_bulb', 20.0, 'Хэрэглээ'),
                ])
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: plate,
                            shape: BoxShape.circle,
                          ),
                          child: _Icon(name, size: size, color: icon),
                        ),
                        // Figma's 12 gap is to the cap line; Manrope's ascent sits
                        // ~5px above the caps inside the line box.
                        const SizedBox(height: 7),
                        _Txt(
                          label,
                          _mr(14, FontWeight.w600, look.ink),
                          drop: true,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 222,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (skeleton)
                      ColoredBox(color: block)
                    else
                      Image.asset(
                        'assets/images/banner_huurimtlaltai.png',
                        fit: BoxFit.cover,
                      ),
                    if (!skeleton)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 204,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < 4; i++) ...[
                              if (i > 0) const SizedBox(width: 6),
                              Container(
                                width: i == 0 ? 16 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(
                                    alpha: i == 0 ? 1 : 0.25,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (!skeleton)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    _Txt(
                      'Сүүлийн гүйлгээ',
                      _mr(14, FontWeight.w500, look.muted, height: lh),
                    ),
                    const Spacer(),
                    _Txt(
                      'Хуулга',
                      _mr(14, FontWeight.w700, link, height: lh),
                      bar: link,
                    ),
                    _Icon('caret_right', size: 16, color: link),
                  ],
                ),
              ),
            for (final incoming in const [true, false, true, false])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: incoming
                            ? Color.alphaBlend(
                                _green.withValues(alpha: 0.06),
                                look.surface,
                              )
                            : Color.alphaBlend(
                                const Color(
                                  0xFFE1E1E1,
                                ).withValues(alpha: look.isDark ? 0.12 : 0.5),
                                look.surface,
                              ),
                        shape: BoxShape.circle,
                      ),
                      child: _Icon(
                        incoming ? 'tx_in' : 'tx_out',
                        size: 24,
                        color: incoming ? null : look.muted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _Txt(
                                '03/05/2023 15:10',
                                _mr(
                                  14,
                                  FontWeight.w500,
                                  look.muted,
                                  height: lh,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: skeleton
                                      ? _Txt(
                                          incoming
                                              ? '+260,000,000,000.78'
                                              : '-260,000,000,000.78',
                                          _mr(
                                            16,
                                            FontWeight.w600,
                                            incoming ? _green : look.ink,
                                            height: 22 / 16,
                                          ),
                                          bar: incoming
                                              ? _green.withValues(alpha: 0.85)
                                              : null,
                                          clamp: true,
                                        )
                                      : FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            incoming
                                                ? '+260,000,000,000.78'
                                                : '-260,000,000,000.78',
                                            style: _mr(
                                              16,
                                              FontWeight.w600,
                                              incoming ? _green : look.ink,
                                              height: 22 / 16,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                          if (!skeleton) ...[
                            const SizedBox(height: 4),
                            _Txt(
                              'POS Normal Purchase Ner/HaanaPOS Normal Purchase Ner/Haana',
                              _mr(14, FontWeight.w500, look.ink, height: lh),
                              clamp: true,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nav bar (74361:5230)
// ---------------------------------------------------------------------------

/// Floating nav pill: Нүүр active on an accent disc.
class _NavBar extends StatelessWidget {
  const _NavBar({required this.look});
  final Look look;

  @override
  Widget build(BuildContext context) {
    const items = [
      ('nav_home_glyph', 'Нүүр'),
      ('nav_qr', 'QR төлбөр'),
      ('nav_transfer', 'Шилжүүлэг'),
      ('nav_services', 'Үйлчилгээ'),
    ];
    final active = readable(look.accent, look.surface);
    return Container(
      width: 358,
      height: 68,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: look.surface.withValues(alpha: look.isDark ? 0.92 : 0.94),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: look.isDark ? look.divider : Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: look.isDark ? 0.4 : 0.13),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: Container(
                decoration: i == 0
                    ? BoxDecoration(
                        color: Color.alphaBlend(
                          look.accent.withValues(alpha: 0.10),
                          look.surface,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      )
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (i == 0)
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: look.accent,
                          shape: BoxShape.circle,
                        ),
                        child: _Icon(
                          items[i].$1,
                          size: 18,
                          color: look.onAccent,
                        ),
                      )
                    else if (_Skeleton.of(context))
                      // A plain dot where the icon would be.
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: look.ink.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      _Icon(items[i].$1, size: 24, color: look.ink),
                    if (!_Skeleton.of(context)) const SizedBox(height: 6),
                    _Txt(
                      items[i].$2,
                      _mr(
                        12,
                        i == 0 ? FontWeight.w700 : FontWeight.w500,
                        i == 0 ? active : look.ink,
                        ls: -0.48,
                        height: 1.074,
                      ),
                      bar: i == 0 ? active : null,
                      drop: true,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// [TdboHomeView] as a skeleton at the Figma frame size (425×912), scaled to
/// [width].
class TdboHomePreview extends StatelessWidget {
  const TdboHomePreview({super.key, required this.look, required this.width});
  final Look look;
  final double width;

  static const phone = Size(425, 912);

  @override
  Widget build(BuildContext context) {
    final s = width / phone.width;
    return SizedBox(
      width: width,
      height: phone.height * s,
      child: FittedBox(
        alignment: Alignment.topCenter,
        child: SizedBox.fromSize(
          size: phone,
          child: IgnorePointer(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: phone,
                padding: EdgeInsets.zero,
                viewPadding: EdgeInsets.zero,
                textScaler: TextScaler.noScaling,
              ),
              child: TdboHomeView(look: look, preview: true),
            ),
          ),
        ),
      ),
    );
  }
}
