import 'package:flutter/material.dart';

/// Горим — the four modes on the current «Өнгө солих» screen.
enum ModeChoice {
  tsagaan('Цагаан'),
  khar('Хар'),
  system('Систем'),
  baraan('Бараан');

  const ModeChoice(this.label);
  final String label;
}

/// Өнгө — the eight colours on the current screen, sampled from it.
enum Accent {
  blue(Color(0xFF0054A6)),
  pink(Color(0xFFD81B60)),
  navy(Color(0xFF102751)),
  purple(Color(0xFF6A1B9A)),
  green(Color(0xFF0E6447)),
  tan(Color(0xFFA68A64)),
  orange(Color(0xFFE65100)),
  olive(Color(0xFF6B8E23));

  const Accent(this.color);
  final Color color;
}

@immutable
class ThemeSpec {
  const ThemeSpec(this.mode, this.accent);
  final ModeChoice mode;
  final Accent accent;

  ThemeSpec copyWith({ModeChoice? mode, Accent? accent}) =>
      ThemeSpec(mode ?? this.mode, accent ?? this.accent);

  @override
  bool operator ==(Object other) =>
      other is ThemeSpec && other.mode == mode && other.accent == accent;

  @override
  int get hashCode => Object.hash(mode, accent);
}

/// Surface colours for one resolved look (light, black or navy-dark) plus the
/// accent tuned for it.
@immutable
class Look extends ThemeExtension<Look> {
  const Look({
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.divider,
    required this.accent,
    required this.onAccent,
    required this.tint,
    required this.brand,
  });

  final bool isDark;
  final Color bg;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color divider;

  /// The chosen colour; lifted toward white on dark backgrounds until it
  /// reaches 4.5:1, so navy or purple stay visible.
  final Color accent;

  /// White or ink, whichever reads better on [accent].
  final Color onAccent;

  /// Accent washed into the background — Base's tinted header and tiles.
  final Color tint;

  /// The chosen colour exactly as picked (not lifted); the home header is
  /// built from it.
  final Color brand;

  static const _light = (
    bg: Color(0xFFF5F9F8),
    surface: Colors.white,
    ink: Color(0xFF242424),
    muted: Color(0xFF75808A),
    divider: Color(0xFFE4EBE9),
  );
  static const _black = (
    bg: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    ink: Color(0xFFF2F2F2),
    muted: Color(0xFF9AA0A6),
    divider: Color(0xFF2C2C2C),
  );
  static const _navy = (
    bg: Color(0xFF0B0D12),
    surface: Color(0xFF161A23),
    ink: Color(0xFFEEF1F6),
    muted: Color(0xFF8B93A1),
    divider: Color(0xFF242A36),
  );

  /// [mode] must already be resolved: tsagaan, khar or baraan.
  factory Look.of(ModeChoice mode, Accent accent) {
    final s = switch (mode) {
      ModeChoice.khar => _black,
      ModeChoice.baraan => _navy,
      _ => _light,
    };
    final dark = mode == ModeChoice.khar || mode == ModeChoice.baraan;
    var a = accent.color;
    if (dark) {
      for (var k = 0.0; k <= 0.8 && _contrast(a, s.bg) < 4.5; k += 0.05) {
        a = Color.lerp(accent.color, Colors.white, k)!;
      }
    }
    final onA =
        _contrast(Colors.white, a) >= 4.5 ||
            _contrast(Colors.white, a) > _contrast(s.ink, a)
        ? Colors.white
        : const Color(0xFF242424);
    return Look(
      isDark: dark,
      bg: s.bg,
      surface: s.surface,
      ink: s.ink,
      muted: s.muted,
      divider: s.divider,
      accent: a,
      onAccent: onA,
      tint: Color.alphaBlend(a.withValues(alpha: dark ? 0.16 : 0.10), s.bg),
      brand: accent.color,
    );
  }

  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance(), lb = b.computeLuminance();
    return (la > lb ? la + 0.05 : lb + 0.05) /
        (la > lb ? lb + 0.05 : la + 0.05);
  }

  static Look read(BuildContext context) =>
      Theme.of(context).extension<Look>()!;

  @override
  Look copyWith() => this;

  @override
  Look lerp(Look? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return Look(
      isDark: t < 0.5 ? isDark : other.isDark,
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      ink: l(ink, other.ink),
      muted: l(muted, other.muted),
      divider: l(divider, other.divider),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      tint: l(tint, other.tint),
      brand: l(brand, other.brand),
    );
  }
}

ThemeData lookTheme(Look look) => ThemeData(
  brightness: look.isDark ? Brightness.dark : Brightness.light,
  fontFamily: 'Manrope',
  scaffoldBackgroundColor: look.bg,
  colorScheme: ColorScheme.fromSeed(
    seedColor: look.accent,
    brightness: look.isDark ? Brightness.dark : Brightness.light,
    primary: look.accent,
    surface: look.surface,
  ),
  splashFactory: NoSplash.splashFactory,
  extensions: [look],
);

double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
}

/// [c] pushed toward black (light [bg]) or white (dark [bg]) until it reaches
/// [ratio] against [bg].
Color readable(Color c, Color bg, {double ratio = 4.5}) {
  final target = bg.computeLuminance() > 0.4 ? Colors.black : Colors.white;
  var out = c;
  for (var k = 0.05; k <= 0.9 && contrast(out, bg) < ratio; k += 0.05) {
    out = Color.lerp(c, target, k)!;
  }
  return out;
}
