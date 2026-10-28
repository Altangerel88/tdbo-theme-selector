import 'package:flutter/material.dart';

/// TDBO colours. Light values are the TDBO 2.0 Figma tokens (Main/Black,
/// Blue/Main, navy home header). TDBO has no dark spec yet, so the dark set is
/// an adaptation built on the same navy.
@immutable
class TdboPalette extends ThemeExtension<TdboPalette> {
  const TdboPalette({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.divider,
    required this.header,
    required this.headerStreak,
    required this.skeleton,
  });

  final Color bg;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color divider;
  final Color header;
  final Color headerStreak;
  final Color skeleton;

  static const light = TdboPalette(
    bg: Color(0xFFF7F7F7),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF242424), // Main/Black/Primary
    muted: Color(0xFF75808A), // Main/Black/Secondary
    accent: Color(0xFF0054A6), // Blue/Main
    divider: Color(0xFFEAEAEA),
    header: Color(0xFF07172F),
    headerStreak: Color(0xFF1B4A8E),
    skeleton: Color(0xFFEDEFF2),
  );

  static const dark = TdboPalette(
    bg: Color(0xFF0A1424),
    surface: Color(0xFF132036),
    ink: Color(0xFFF2F5F9),
    muted: Color(0xFF8E9AAB),
    accent: Color(0xFF4A9BFF),
    divider: Color(0xFF1F2C44),
    header: Color(0xFF040B17),
    headerStreak: Color(0xFF15386B),
    skeleton: Color(0xFF1D2B45),
  );

  static TdboPalette of(BuildContext context) =>
      Theme.of(context).extension<TdboPalette>()!;

  @override
  TdboPalette copyWith() => this;

  @override
  TdboPalette lerp(TdboPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return TdboPalette(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      ink: l(ink, other.ink),
      muted: l(muted, other.muted),
      accent: l(accent, other.accent),
      divider: l(divider, other.divider),
      header: l(header, other.header),
      headerStreak: l(headerStreak, other.headerStreak),
      skeleton: l(skeleton, other.skeleton),
    );
  }
}

ThemeData tdboTheme(Brightness brightness) {
  final p = brightness == Brightness.light
      ? TdboPalette.light
      : TdboPalette.dark;
  return ThemeData(
    brightness: brightness,
    fontFamily: 'Manrope',
    scaffoldBackgroundColor: p.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.accent,
      brightness: brightness,
      primary: p.accent,
      surface: p.surface,
    ),
    splashFactory: NoSplash.splashFactory,
    extensions: [p],
  );
}

/// The three choices, in carousel order.
enum AppTheme {
  light('Цайвар', ThemeMode.light),
  dark('Бараан', ThemeMode.dark),
  system('Систем', ThemeMode.system);

  const AppTheme(this.label, this.mode);
  final String label;
  final ThemeMode mode;
}
