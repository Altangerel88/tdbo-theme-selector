import 'package:flutter/material.dart';

import 'theme_model.dart';

/// The dashboard header background: the colour's own photo, cropped to
/// cover, washed with the colour and darkened from the top so the header's
/// white text reads. Dark modes darken it further.
class HeaderPhoto extends StatelessWidget {
  const HeaderPhoto({super.key, required this.accent, required this.look});

  final Accent accent;
  final Look look;

  @override
  Widget build(BuildContext context) {
    final dark = look.isDark;
    // Black scrim, strongest behind the greeting and balance at the top.
    final scrim = [
      for (final a
          in dark ? const [0.68, 0.52, 0.62] : const [0.46, 0.26, 0.38])
        (a + accent.photoDim).clamp(0.0, 0.9),
    ];
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          accent.photo,
          fit: BoxFit.cover,
          alignment: accent.photoAlignment,
          gaplessPlayback: true,
        ),
        ColoredBox(color: look.brand.withValues(alpha: dark ? 0.16 : 0.22)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                for (final a in scrim) Colors.black.withValues(alpha: a),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
