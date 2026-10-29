import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'theme_model.dart';

/// The TDBO 2.0 retail home (Figma 74444:14342 layout, measurements from
/// ~/tdbo_retail_home), recoloured from a [Look]: the header is built from the
/// chosen colour, and the quick-action plates, «Хуулга» link and active nav
/// disc use it. Used full-size as the home and scaled down as the preview.
class TdboHomeView extends StatelessWidget {
  const TdboHomeView({
    super.key,
    required this.look,
    this.onAvatar,
    this.balanceHidden = false,
    this.onToggleBalance,
    this.fakeStatusBar = false,
  });

  final Look look;
  final VoidCallback? onAvatar;
  final bool balanceHidden;
  final VoidCallback? onToggleBalance;

  /// Draws a 9:41 status bar (for the scaled preview, which has no real one).
  final bool fakeStatusBar;

  @override
  Widget build(BuildContext context) {
    final top = fakeStatusBar ? 47.0 : MediaQuery.paddingOf(context).top;
    return ColoredBox(
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
                      child: CustomPaint(painter: _HeaderBg(look)),
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
          if (fakeStatusBar)
            const Positioned(left: 0, right: 0, top: 0, child: _StatusBar()),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Center(child: _NavBar(look: look)),
          ),
        ],
      ),
    );
  }
}

/// Header ground: the chosen colour taken most of the way to near-black, with
/// the TDBO diagonal light streaks on the right.
class _HeaderBg extends CustomPainter {
  _HeaderBg(this.look);
  final Look look;

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
  bool shouldRepaint(_HeaderBg old) => old.look != look;
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 47,
    child: Padding(
      padding: EdgeInsets.fromLTRB(34, 14, 26, 0),
      child: Row(
        children: [
          Text(
            '9:41',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Spacer(),
          Icon(
            Icons.signal_cellular_alt_rounded,
            size: 18,
            color: Colors.white,
          ),
          SizedBox(width: 5),
          Icon(Icons.wifi_rounded, size: 18, color: Colors.white),
          SizedBox(width: 5),
          Icon(Icons.battery_full_rounded, size: 20, color: Colors.white),
        ],
      ),
    ),
  );
}

class _Icon extends StatelessWidget {
  const _Icon(this.name, {required this.size, this.color});
  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
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
    TextStyle t(double size, FontWeight w, Color c) => TextStyle(
      fontFamily: 'Manrope',
      fontSize: size,
      fontWeight: w,
      color: c,
    );

    return Padding(
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
                    Text(
                      'Өдрийн мэнд!',
                      style: t(13, FontWeight.w500, white72),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Алтангэрэл',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t(18, FontWeight.w700, Colors.white),
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
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MN91 0004 0040 0238 9817',
                style: t(13, FontWeight.w500, white72),
              ),
              const SizedBox(width: 8),
              const _Icon('copy', size: 16),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                balanceHidden ? '••• ••• •••.••' : '123,456,789.12',
                style: t(24, FontWeight.w700, Colors.white),
              ),
              const SizedBox(width: 7),
              Text(
                'MNT',
                style: t(
                  16,
                  FontWeight.w700,
                  Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Pill(
                'Дансны хуулга',
                fill: Colors.white,
                text: readable(look.brand, Colors.white),
              ),
              const SizedBox(width: 10),
              _Pill(
                'Данс хайх',
                fill: Colors.white.withValues(alpha: 0.12),
                text: Colors.white,
                rim: true,
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: child,
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill(
    this.label, {
    required this.fill,
    required this.text,
    this.rim = false,
  });
  final String label;
  final Color fill;
  final Color text;
  final bool rim;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(22),
      border: rim
          ? Border.all(color: Colors.white.withValues(alpha: 0.25))
          : null,
    ),
    child: Text(
      label,
      style: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: text,
      ),
    ),
  );
}

class _Content extends StatelessWidget {
  const _Content({required this.look});
  final Look look;

  @override
  Widget build(BuildContext context) {
    final plate = Color.alphaBlend(
      look.accent.withValues(alpha: look.isDark ? 0.18 : 0.09),
      look.surface,
    );
    final icon = readable(
      look.isDark ? look.accent : look.brand,
      plate,
      ratio: 3,
    );
    TextStyle t(double size, FontWeight w, Color c) => TextStyle(
      fontFamily: 'Manrope',
      fontSize: size,
      fontWeight: w,
      color: c,
      height: 22 / 14,
    );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: ColoredBox(
        color: look.surface,
        child: ListView(
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
                        const SizedBox(height: 7),
                        Text(
                          label,
                          maxLines: 1,
                          style: t(
                            14,
                            FontWeight.w600,
                            look.ink,
                          ).copyWith(height: null),
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
                    Image.asset(
                      'assets/images/banner_huurimtlaltai.png',
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 12,
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
                                  alpha: i == 0 ? 1 : 0.35,
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
            SizedBox(
              height: 24,
              child: Row(
                children: [
                  Text(
                    'Сүүлийн гүйлгээ',
                    style: t(
                      14,
                      FontWeight.w500,
                      look.muted,
                    ).copyWith(height: null),
                  ),
                  const Spacer(),
                  Text(
                    'Хуулга',
                    style: t(
                      14,
                      FontWeight.w700,
                      readable(look.accent, look.surface),
                    ).copyWith(height: null),
                  ),
                  _Icon(
                    'caret_right',
                    size: 16,
                    color: readable(look.accent, look.surface),
                  ),
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
                                const Color(0xFF28A745).withValues(alpha: 0.08),
                                look.surface,
                              )
                            : Color.alphaBlend(
                                look.muted.withValues(alpha: 0.14),
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
                              Text(
                                '03/05/2023 15:10',
                                style: t(14, FontWeight.w500, look.muted),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      incoming
                                          ? '+260,000,000,000.78'
                                          : '-260,000,000,000.78',
                                      style: t(
                                        14,
                                        FontWeight.w600,
                                        incoming
                                            ? const Color(0xFF28A745)
                                            : look.ink,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'POS Normal Purchase Ner/HaanaPOS Normal Purchase Ner/Haana',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t(14, FontWeight.w500, look.ink),
                          ),
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

/// Floating nav pill (74444:14489): Нүүр active on an accent disc.
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
            color: Colors.black.withValues(alpha: look.isDark ? 0.4 : 0.12),
            blurRadius: 16,
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
                    else
                      _Icon(items[i].$1, size: 24, color: look.ink),
                    const SizedBox(height: 6),
                    Text(
                      items[i].$2,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        letterSpacing: -0.48,
                        fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
                        color: i == 0
                            ? readable(look.accent, look.surface)
                            : look.ink,
                      ),
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

/// [TdboHomeView] drawn at phone size (402×874) and scaled to [width].
class TdboHomePreview extends StatelessWidget {
  const TdboHomePreview({super.key, required this.look, required this.width});
  final Look look;
  final double width;

  static const phone = Size(402, 874);

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
              child: TdboHomeView(look: look, fakeStatusBar: true),
            ),
          ),
        ),
      ),
    );
  }
}
