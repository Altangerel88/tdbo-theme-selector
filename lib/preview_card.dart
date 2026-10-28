import 'package:flutter/material.dart';

import 'tokens.dart';

/// A miniature TDBO home screen. It paints with the palette it is given, not
/// the ambient theme, so each card always shows its own look.
class HomePreview extends StatelessWidget {
  const HomePreview({super.key, required this.palette});

  final TdboPalette palette;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final p = palette;
        final glass = Colors.white.withValues(alpha: 0.18);
        final headerH = h * 0.56;
        final pad = w * 0.075;

        Widget dot(double d) => Container(
          width: d,
          height: d,
          decoration: BoxDecoration(color: glass, shape: BoxShape.circle),
        );
        Widget bar(double width, double height, Color color) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        );

        Widget row() => Row(
          children: [
            Container(
              width: w * 0.12,
              height: w * 0.12,
              decoration: BoxDecoration(
                color: p.skeleton,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: w * 0.05),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  bar(w * 0.38, w * 0.035, p.skeleton),
                  SizedBox(height: w * 0.025),
                  bar(w * 0.24, w * 0.028, p.skeleton),
                ],
              ),
            ),
            bar(w * 0.14, w * 0.035, p.skeleton),
          ],
        );

        return Container(
          color: p.bg,
          child: Stack(
            children: [
              // Navy header with the TDBO diagonal streak.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: headerH,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [p.header, p.headerStreak, p.header],
                      stops: const [0.15, 0.55, 0.95],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: pad,
                right: pad,
                top: pad,
                child: Row(
                  children: [
                    dot(w * 0.12),
                    const Spacer(),
                    bar(w * 0.3, w * 0.12, glass),
                    const Spacer(),
                    dot(w * 0.12),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: headerH * 0.36,
                child: Column(
                  children: [
                    Text(
                      'Харилцах · MNT',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: w * 0.06,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: w * 0.035),
                    bar(
                      w * 0.44,
                      w * 0.07,
                      Colors.white.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: pad,
                right: pad,
                top: headerH - w * 0.26,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (_) => dot(w * 0.13)),
                ),
              ),
              // Content sheet over the header's bottom edge.
              Positioned(
                left: w * 0.05,
                right: w * 0.05,
                top: headerH - w * 0.06,
                bottom: w * 0.05,
                child: Container(
                  padding: EdgeInsets.all(pad),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(w * 0.06),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(w * 0.3, w * 0.04, p.skeleton),
                      SizedBox(height: w * 0.07),
                      row(),
                      SizedBox(height: w * 0.06),
                      row(),
                      SizedBox(height: w * 0.06),
                      row(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Left half light, right half dark — the same split as the System swatch.
class SystemPreview extends StatelessWidget {
  const SystemPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        HomePreview(palette: TdboPalette.light),
        ClipRect(
          clipper: _RightHalf(),
          child: HomePreview(palette: TdboPalette.dark),
        ),
      ],
    );
  }
}

class _RightHalf extends CustomClipper<Rect> {
  const _RightHalf();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(size.width / 2, 0, size.width, size.height);

  @override
  bool shouldReclip(_RightHalf oldClipper) => false;
}
