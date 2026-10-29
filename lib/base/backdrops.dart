import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'header_logo_v8.dart';
import 'tdb_icon.dart';
import 'theme_model.dart';

/// The dashboard header background for a [Backdrop], built from the chosen
/// colour ([Look.brand]) so every Өнгө has its own set. All of them keep the
/// header dark enough for its white text.
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
    Backdrop.plain => CustomPaint(painter: _GradientPainter(look)),
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

/// Энгийн / Шугам: a diagonal gradient, optionally with the TDBO light streaks
/// on the right.
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
