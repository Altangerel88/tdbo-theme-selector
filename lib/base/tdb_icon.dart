import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_parsing/path_parsing.dart';

import 'theme_model.dart';

/// The TDB app icon (tdb-logo.svg, 512×512), drawn as it would sit on the
/// phone's home screen for a given [Look]:
/// - light: white square, the mark in the chosen colour (blue keeps the logo's
///   own #0086D6→#0093D9);
/// - dark (Хар, Бараан): an iOS-style dark square from the mode's background,
///   the mark in the colour lifted for contrast.
///
/// Painted from the SVG's own paths, gradients and drop shadows (dy 4,
/// blur 9, black 25%); flutter_svg drops the shadows, and without them the
/// interlocking arrows read as one shape.
class TdbAppIcon extends StatelessWidget {
  const TdbAppIcon({super.key, required this.look, required this.size});

  final Look look;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _IconPainter(look));
}

class _Piece {
  const _Piece(
    this.d, {
    required this.shadow,
    required this.from,
    required this.to,
  });
  final String d;
  final bool shadow;
  final Offset from, to;
}

// From tdb-logo.svg, in paint order.
const _pieces = [
  _Piece(
    'M366.582 375.175C351.486 380.138 335.623 382.117 319.922 381.171C318.356 383.062 316.687 384.893 314.915 386.666C282.434 419.144 229.778 419.144 197.297 386.666C164.817 354.188 164.817 301.535 197.297 269.056L220.103 291.861V220.096H148.318L171.124 242.885C124.198 289.808 124.198 365.885 171.124 412.808C218.05 459.73 294.132 459.73 341.058 412.808C352.225 401.671 360.732 388.866 366.582 375.175Z',
    shadow: true,
    from: Offset(138.936, 226.306),
    to: Offset(352.831, 462.435),
  ),
  _Piece(
    'M136.829 366.574C131.867 351.479 129.887 335.617 130.833 319.917C128.942 318.352 127.11 316.683 125.338 314.91C92.8578 282.432 92.8578 229.779 125.338 197.301C157.818 164.823 210.475 164.823 242.955 197.301L220.15 220.105H291.919V148.325L269.128 171.129C222.203 124.207 146.12 124.207 99.1943 171.129C52.2686 218.052 52.2686 294.13 99.1943 341.052C110.346 352.218 123.152 360.725 136.829 366.574Z',
    shadow: true,
    from: Offset(66.9704, 142.223),
    to: Offset(283.878, 376.037),
  ),
  _Piece(
    'M145.426 136.825C160.521 131.862 176.385 129.883 192.086 130.828C193.651 128.938 195.32 127.106 197.093 125.334C229.573 92.8558 282.23 92.8558 314.71 125.334C347.19 157.812 347.19 210.465 314.71 242.943L291.904 220.139V291.904H363.689L340.883 269.115C387.809 222.192 387.809 146.115 340.883 99.1919C293.958 52.2693 217.875 52.2693 170.949 99.1919C159.783 110.343 151.275 123.148 145.426 136.825Z',
    shadow: false,
    from: Offset(148.432, 70.2107),
    to: Offset(362.327, 306.339),
  ),
  _Piece(
    'M375.141 145.421C380.104 160.515 382.083 176.378 381.137 192.078C383.028 193.643 384.86 195.312 386.632 197.085C419.112 229.563 419.112 282.216 386.632 314.694C354.152 347.172 301.495 347.172 269.015 314.694L291.82 291.89H220.051V363.669L242.871 340.851C289.797 387.773 365.88 387.773 412.805 340.851C459.731 293.928 459.731 217.85 412.805 170.928C401.639 159.777 388.833 151.27 375.141 145.421Z',
    shadow: true,
    from: Offset(223.022, 151.706),
    to: Offset(439.912, 385.547),
  ),
];

class _PathBuilder implements PathProxy {
  final path = Path();

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void close() => path.close();
}

Path _parse(String d) {
  final builder = _PathBuilder();
  writeSvgPathDataToPath(d, builder);
  return builder.path;
}

final List<Path> _paths = [for (final p in _pieces) _parse(p.d)];

/// Draws the TDB mark alone (no square, no shadows) in [color], in the SVG's
/// 512-unit space; scale the canvas first.
void paintTdbMark(Canvas canvas, Color color) {
  final paint = Paint()..color = color;
  for (final path in _paths) {
    canvas.drawPath(path, paint);
  }
}

/// The logo's own blue.
const _logoBlue = [Color(0xFF0086D6), Color(0xFF0093D9)];

class _IconPainter extends CustomPainter {
  _IconPainter(this.look);
  final Look look;

  List<Color> get _mark {
    final base = look.isDark ? look.accent : look.brand;
    if (look.brand.toARGB32() == Accent.blue.color.toARGB32()) return _logoBlue;
    return [base, Color.lerp(base, Colors.white, 0.12)!];
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 512);
    const square = Rect.fromLTWH(0, 0, 512, 512);
    canvas.clipRRect(
      RRect.fromRectAndRadius(square, const Radius.circular(120)),
    );
    final ground = Paint();
    if (look.isDark) {
      ground.shader = ui.Gradient.linear(
        const Offset(256, 0),
        const Offset(256, 512),
        [
          Color.lerp(look.bg, Colors.white, 0.12)!,
          Color.lerp(look.bg, Colors.black, 0.4)!,
        ],
      );
    } else {
      ground.color = Colors.white;
    }
    canvas.drawRect(square, ground);
    final mark = _mark;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: look.isDark ? 0.45 : 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    for (var i = 0; i < _pieces.length; i++) {
      final piece = _pieces[i];
      final path = _paths[i];
      if (piece.shadow) canvas.drawPath(path.shift(const Offset(0, 4)), shadow);
      canvas.drawPath(
        path,
        // SVG gradients run from point to point (gradientUnits=userSpaceOnUse).
        Paint()..shader = ui.Gradient.linear(piece.from, piece.to, mark),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.look != look;
}
