import 'package:flutter/material.dart';

import 'tdb_icon.dart';
import 'theme_model.dart';

/// The phone's home screen at the Figma frame size (425×912), scaled to
/// [width]: a plain wallpaper, a grid of placeholder icons and the TDB app
/// icon in the chosen Горим and Өнгө. Kept as bare as the dashboard skeleton.
class HomeScreenPreview extends StatelessWidget {
  const HomeScreenPreview({super.key, required this.look, required this.width});

  final Look look;
  final double width;

  static const phone = Size(425, 912);

  // iOS-like grid: 4 columns of 64pt icons.
  static const _icon = 64.0;
  static const _side = 28.0;
  static const _top = 76.0;
  static const _pitch = 92.0;
  static const _rows = 6;

  /// Where the TDB icon sits: second row, second column.
  static const _tdbRow = 1, _tdbCol = 1;

  @override
  Widget build(BuildContext context) {
    final s = width / phone.width;
    return SizedBox(
      width: width,
      height: phone.height * s,
      child: FittedBox(
        alignment: Alignment.topCenter,
        child: SizedBox.fromSize(size: phone, child: _screen()),
      ),
    );
  }

  Widget _screen() {
    final wallpaper = look.isDark
        ? [
            Color.lerp(look.bg, Colors.white, 0.07)!,
            Color.lerp(look.bg, Colors.black, 0.35)!,
          ]
        : const [Color(0xFFEEF1F3), Color(0xFFD9DFE3)];
    final placeholder = look.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.72);
    const gap = (425 - 2 * _side - 4 * _icon) / 3;
    final radius = BorderRadius.circular(_icon * 120 / 512);

    Widget slot(int row, int col) {
      final tdb = row == _tdbRow && col == _tdbCol;
      return Positioned(
        left: _side + col * (_icon + gap),
        top: _top + row * _pitch,
        child: tdb
            ? TdbAppIcon(look: look, size: _icon)
            : Container(
                width: _icon,
                height: _icon,
                decoration: BoxDecoration(
                  color: placeholder,
                  borderRadius: radius,
                ),
              ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: wallpaper,
        ),
      ),
      child: Stack(
        children: [
          for (var r = 0; r < _rows; r++)
            for (var c = 0; c < 4; c++) slot(r, c),
        ],
      ),
    );
  }
}
