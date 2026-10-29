import 'dart:math' as math;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'header_logo_v8.dart';
import 'tdb_icon.dart';
import 'theme_model.dart';

/// The dashboard header background for a [Backdrop], built from the chosen
/// colour ([Look.brand]). Each Өнгө has its own scene ([Accent.backdrop]); all
/// are night or dusk, so the header stays dark enough for its white text.
class HeaderBackdrop extends StatelessWidget {
  const HeaderBackdrop({
    super.key,
    required this.backdrop,
    required this.look,
    this.underlap = 0,
  });

  final Backdrop backdrop;
  final Look look;

  /// How far the background runs under the sheet below it.
  final double underlap;

  @override
  Widget build(BuildContext context) => switch (backdrop) {
    Backdrop.lines => CustomPaint(
      painter: _GradientPainter(look, streaks: true),
    ),
    Backdrop.knot => HeaderLogoV8(
      underlap: underlap,
      ground: _ground(look),
      line: readable(
        look.isDark ? look.accent : look.brand,
        _ground(look),
        ratio: 3,
      ),
    ),
    Backdrop.mountains => CustomPaint(
      painter: _MountainsPainter(look, underlap),
    ),
    Backdrop.pattern => CustomPaint(painter: _PatternPainter(look)),
    Backdrop.bokeh => CustomPaint(painter: _BokehPainter(look)),
    Backdrop.nebula => CustomPaint(painter: _NebulaPainter(look)),
    Backdrop.aurora => CustomPaint(painter: _AuroraPainter(look, underlap)),
    Backdrop.dunes => CustomPaint(painter: _DunesPainter(look, underlap)),
    Backdrop.sunset => CustomPaint(painter: _SunsetPainter(look, underlap)),
  };
}

const _night = Color(0xFF00040C);
const _nightDark = Color(0xFF030507);

/// The colour taken most of the way to near-black: the header's ground.
Color _base(Look look) => Color.lerp(
  look.brand,
  look.isDark ? _nightDark : _night,
  look.isDark ? 0.84 : 0.76,
)!;

/// Ground for the knot: in dark modes the mode's own background with a wash
/// of the colour (as first built), in light the header's usual ground.
Color _ground(Look look) =>
    look.isDark ? Color.lerp(look.bg, look.brand, 0.12)! : _base(look);

/// Шугам: a diagonal gradient with the TDBO light streaks on the right (and
/// the plain gradient other scenes start from).
class _GradientPainter extends CustomPainter {
  _GradientPainter(this.look, {this.streaks = false});
  final Look look;
  final bool streaks;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGround(canvas, size, look);
    if (!streaks) return;
    final streak = Color.lerp(look.brand, Colors.white, 0.25)!;
    final rect = Offset.zero & size;
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
  bool shouldRepaint(_GradientPainter old) =>
      old.look != look || old.streaks != streaks;
}

void _paintGround(Canvas canvas, Size size, Look look) {
  final base = _base(look);
  final lift = Color.lerp(
    look.brand,
    look.isDark ? _nightDark : _night,
    (look.isDark ? 0.84 : 0.76) - 0.1,
  )!;
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
}

/// Уул: a night sky in the colour, a moon and a few stars, and three ridges
/// of mountains stepping darker toward the front.
class _MountainsPainter extends CustomPainter {
  _MountainsPainter(this.look, this.underlap);
  final Look look;
  final double underlap;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    // The part of the header above the sheet.
    final h = size.height - underlap;
    final base = _base(look);
    final glow = Color.lerp(base, look.brand, 0.6)!;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(base, Colors.black, 0.35)!, glow],
          stops: const [0.2, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Stars, from a fixed seed so they never jump.
    final rnd = math.Random(41);
    final star = Paint()..color = Colors.white;
    for (var i = 0; i < 26; i++) {
      final p = Offset(rnd.nextDouble() * w, rnd.nextDouble() * h * 0.55);
      canvas.drawCircle(
        p,
        0.6 + rnd.nextDouble() * 0.9,
        star
          ..color = Colors.white.withValues(
            alpha: 0.25 + rnd.nextDouble() * 0.4,
          ),
      );
    }

    // A crescent: a disc with a ground-coloured disc taken out of it.
    // Clear sky between the name and the header's round buttons.
    final moon = Offset(w * 0.62, h * 0.17);
    final r = w * 0.032;
    canvas.saveLayer(rect, Paint());
    canvas.drawCircle(
      moon,
      r,
      Paint()..color = Color.lerp(look.brand, Colors.white, 0.85)!,
    );
    canvas.drawCircle(
      moon + Offset(r * 0.55, -r * 0.35),
      r * 0.9,
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();

    // Ridges, back to front.
    for (final (top, amp, seed, mix) in [
      (0.44, 0.24, 3, 0.75),
      (0.60, 0.18, 11, 0.45),
      (0.78, 0.12, 23, 0.0),
    ]) {
      final colour = mix > 0
          ? Color.lerp(Color.lerp(base, Colors.black, 0.25), glow, mix)!
          : Color.lerp(base, Colors.black, 0.45)!;
      canvas.drawPath(
        _ridge(w, size.height, h * top, h * amp, seed),
        Paint()..color = colour,
      );
    }
  }

  /// A ridge line from a few summed waves, peaked with abs(), closed at the
  /// bottom.
  Path _ridge(double w, double bottom, double y, double amp, int seed) {
    final rnd = math.Random(seed);
    final waves = [
      for (var i = 0; i < 3; i++)
        (
          freq: (1.5 + i * 1.7 + rnd.nextDouble()) * math.pi / w,
          phase: rnd.nextDouble() * math.pi * 2,
          weight: 1 / (i + 1),
        ),
    ];
    final path = Path()..moveTo(0, bottom);
    const steps = 48;
    for (var i = 0; i <= steps; i++) {
      final x = w * i / steps;
      var v = 0.0;
      for (final wv in waves) {
        v += wv.weight * math.sin(x * wv.freq + wv.phase).abs();
      }
      path.lineTo(x, y + amp * (0.5 - v / 1.83));
    }
    path
      ..lineTo(w, bottom)
      ..close();
    return path;
  }

  @override
  bool shouldRepaint(_MountainsPainter old) =>
      old.look != look || old.underlap != underlap;
}

/// Хээ: the gradient ground tiled with small TDB marks, staggered and turned
/// a little each, faint like a messenger wallpaper.
class _PatternPainter extends CustomPainter {
  _PatternPainter(this.look);
  final Look look;

  static const _mark = 22.0;
  static const _step = 46.0;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGround(canvas, size, look);
    final colour = Color.lerp(
      look.brand,
      Colors.white,
      0.55,
    )!.withValues(alpha: 0.13);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    var row = 0;
    for (
      var y = -_step / 2;
      y < size.height + _step;
      y += _step * 0.85, row++
    ) {
      final shift = row.isOdd ? _step / 2 : 0.0;
      var col = 0;
      for (
        var x = -_step / 2 + shift;
        x < size.width + _step;
        x += _step, col++
      ) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(((row * 3 + col) % 4) * math.pi / 12);
        canvas.translate(-_mark / 2, -_mark / 2);
        canvas.scale(_mark / 512);
        paintTdbMark(canvas, colour);
        canvas.restore();
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PatternPainter old) => old.look != look;
}

/// Scattered stars from a fixed seed, in the top [depth] of the header.
void _stars(
  Canvas canvas,
  double w,
  double h,
  int seed,
  int count, {
  double depth = 0.6,
}) {
  final rnd = math.Random(seed);
  final paint = Paint();
  for (var i = 0; i < count; i++) {
    final p = Offset(rnd.nextDouble() * w, rnd.nextDouble() * h * depth);
    paint.color = Colors.white.withValues(alpha: 0.2 + rnd.nextDouble() * 0.5);
    canvas.drawCircle(p, 0.5 + rnd.nextDouble() * 0.9, paint);
  }
}

/// A soft round glow: [colour] at [alpha] in the middle, gone at [r].
void _glow(Canvas canvas, Offset c, double r, Color colour, double alpha) {
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..shader = ui.Gradient.radial(c, r, [
        colour.withValues(alpha: alpha),
        colour.withValues(alpha: 0),
      ]),
  );
}

/// Pink: soft out-of-focus lights drifting over the gradient.
class _BokehPainter extends CustomPainter {
  _BokehPainter(this.look);
  final Look look;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGround(canvas, size, look);
    final w = size.width, h = size.height;
    final light = Color.lerp(look.brand, Colors.white, 0.45)!;
    _glow(canvas, Offset(w * 0.82, h * 0.35), w * 0.55, look.brand, 0.35);
    final rnd = math.Random(7);
    for (var i = 0; i < 14; i++) {
      final r = 12 + rnd.nextDouble() * 40;
      canvas.drawCircle(
        Offset(rnd.nextDouble() * w, rnd.nextDouble() * h * 0.9),
        r,
        Paint()
          ..color = light.withValues(alpha: 0.07 + rnd.nextDouble() * 0.16)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(_BokehPainter old) => old.look != look;
}

/// Purple: deep space with coloured gas clouds and stars, a few with glints.
class _NebulaPainter extends CustomPainter {
  _NebulaPainter(this.look);
  final Look look;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Color.lerp(_base(look), Colors.black, 0.35)!,
    );
    final lift = Color.lerp(look.brand, Colors.white, 0.2)!;
    _glow(canvas, Offset(w * 0.78, h * 0.38), w * 0.55, lift, 0.5);
    _glow(
      canvas,
      Offset(w * 0.98, h * 0.8),
      w * 0.42,
      Color.lerp(look.brand, const Color(0xFFFF4FA3), 0.4)!,
      0.32,
    );
    _glow(
      canvas,
      Offset(w * 0.5, h * 0.12),
      w * 0.32,
      Color.lerp(look.brand, const Color(0xFF4F7BFF), 0.45)!,
      0.28,
    );
    _stars(canvas, w, h, 59, 70, depth: 1);
    // Four bright stars with a cross-shaped glint.
    final rnd = math.Random(5);
    for (var i = 0; i < 4; i++) {
      final c = Offset(
        w * (0.5 + rnd.nextDouble() * 0.48),
        h * rnd.nextDouble() * 0.8,
      );
      final len = 4 + rnd.nextDouble() * 4;
      final glint = Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round;
      canvas
        ..drawLine(c - Offset(len, 0), c + Offset(len, 0), glint)
        ..drawLine(c - Offset(0, len), c + Offset(0, len), glint)
        ..drawCircle(c, 1.4, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_NebulaPainter old) => old.look != look;
}

/// Green: northern lights — glowing ribbons over a dark horizon.
class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.look, this.underlap);
  final Look look;
  final double underlap;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height - underlap;
    final base = _base(look);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, h), [
          Color.lerp(base, Colors.black, 0.45)!,
          base,
        ]),
    );
    _stars(canvas, w, h, 17, 28, depth: 0.7);
    final ribbon = Color.lerp(look.brand, const Color(0xFF3CFFB0), 0.5)!;
    for (final (y, amp, freq, phase, thick, alpha) in [
      (0.30, 0.10, 1.6, 0.4, 0.34, 0.55),
      (0.44, 0.08, 2.3, 2.1, 0.26, 0.40),
      (0.20, 0.06, 2.9, 4.0, 0.20, 0.28),
    ]) {
      // A band whose lower edge waves; it glows brightest there and fades
      // upward, like the curtains of an aurora.
      final edge = Path();
      const steps = 40;
      for (var i = 0; i <= steps; i++) {
        final x = w * i / steps;
        final yy = h * (y + amp * math.sin(x / w * math.pi * freq + phase));
        i == 0 ? edge.moveTo(x, yy) : edge.lineTo(x, yy);
      }
      final band = Path.from(edge)
        ..relativeLineTo(0, -h * thick)
        ..lineTo(0, h * (y - thick))
        ..close();
      canvas.drawPath(
        band,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, h * (y + amp)),
            Offset(0, h * (y - thick)),
            [ribbon.withValues(alpha: alpha), ribbon.withValues(alpha: 0)],
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    // Horizon.
    final hills = Path()..moveTo(0, size.height);
    for (var i = 0; i <= 24; i++) {
      final x = w * i / 24;
      hills.lineTo(x, h * (0.84 + 0.04 * math.sin(x / w * math.pi * 3 + 1)));
    }
    hills
      ..lineTo(w, size.height)
      ..close();
    canvas.drawPath(
      hills,
      Paint()..color = Color.lerp(base, Colors.black, 0.55)!,
    );
  }

  @override
  bool shouldRepaint(_AuroraPainter old) =>
      old.look != look || old.underlap != underlap;
}

/// Tan: Gobi dunes at dusk under a low, pale sun.
class _DunesPainter extends CustomPainter {
  _DunesPainter(this.look, this.underlap);
  final Look look;
  final double underlap;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height - underlap;
    final base = _base(look);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, h * 0.7), [
          Color.lerp(base, Colors.black, 0.35)!,
          Color.lerp(base, look.brand, 0.55)!,
        ]),
    );
    final sun = Offset(w * 0.8, h * 0.5);
    _glow(
      canvas,
      sun,
      w * 0.28,
      Color.lerp(look.brand, Colors.white, 0.5)!,
      0.35,
    );
    canvas.drawCircle(
      sun,
      w * 0.045,
      Paint()
        ..color = Color.lerp(
          look.brand,
          Colors.white,
          0.7,
        )!.withValues(alpha: 0.9),
    );

    Path dune(List<double> ys) {
      // ys: start, then (control, control, end) triples, all × h, spread
      // evenly across the width.
      final path = Path()..moveTo(0, h * ys[0]);
      final n = (ys.length - 1) ~/ 3;
      for (var i = 0; i < n; i++) {
        final x0 = w * i / n, x1 = w * (i + 1) / n;
        path.cubicTo(
          x0 + (x1 - x0) * 0.35,
          h * ys[1 + i * 3],
          x0 + (x1 - x0) * 0.65,
          h * ys[2 + i * 3],
          x1,
          h * ys[3 + i * 3],
        );
      }
      return path
        ..lineTo(w, size.height)
        ..lineTo(0, size.height)
        ..close();
    }

    for (final (ys, mix) in [
      ([0.62, 0.50, 0.52, 0.60, 0.66, 0.54, 0.57], 0.48),
      ([0.74, 0.66, 0.70, 0.78, 0.84, 0.68, 0.70], 0.30),
      ([0.90, 0.80, 0.82, 0.88, 0.94, 0.86, 0.84], 0.12),
    ]) {
      canvas.drawPath(
        dune(ys),
        Paint()
          ..color = Color.lerp(
            Color.lerp(base, Colors.black, 0.2),
            look.brand,
            mix,
          )!,
      );
    }
  }

  @override
  bool shouldRepaint(_DunesPainter old) =>
      old.look != look || old.underlap != underlap;
}

/// Orange: the sun setting over the steppe, its lower half cut into bands.
class _SunsetPainter extends CustomPainter {
  _SunsetPainter(this.look, this.underlap);
  final Look look;
  final double underlap;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height - underlap;
    final base = _base(look);
    final horizon = h * 0.8;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, horizon), [
          Color.lerp(base, Colors.black, 0.3)!,
          Color.lerp(base, look.brand, 0.75)!,
        ]),
    );
    final sun = Offset(w * 0.74, horizon);
    final r = w * 0.17;
    _glow(canvas, sun, w * 0.5, look.brand, 0.45);
    // The disc, clipped at the horizon, with gaps cut through its lower half.
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, w, horizon));
    canvas.drawCircle(
      sun,
      r,
      Paint()
        ..shader = ui.Gradient.linear(sun - Offset(0, r), sun, [
          Color.lerp(look.brand, const Color(0xFFFFD27A), 0.65)!,
          Color.lerp(look.brand, Colors.white, 0.1)!,
        ]),
    );
    canvas.restore();
    final clear = Paint()..blendMode = BlendMode.clear;
    for (var i = 0; i < 4; i++) {
      final y = sun.dy - r * (0.62 - i * 0.18);
      canvas.drawRect(
        Rect.fromLTWH(sun.dx - r, y, r * 2, 1.5 + i * 1.3),
        clear,
      );
    }
    canvas.restore();
    // Steppe: a dark band with low hills.
    final land = Path()..moveTo(0, size.height);
    for (var i = 0; i <= 24; i++) {
      final x = w * i / 24;
      land.lineTo(
        x,
        horizon - h * 0.025 * (1 + math.sin(x / w * math.pi * 2.4)),
      );
    }
    land
      ..lineTo(w, size.height)
      ..close();
    canvas.drawPath(
      land,
      Paint()..color = Color.lerp(base, Colors.black, 0.5)!,
    );
  }

  @override
  bool shouldRepaint(_SunsetPainter old) =>
      old.look != look || old.underlap != underlap;
}
