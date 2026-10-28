import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'preview_card.dart';
import 'tokens.dart';

/// Revolut-style theme picker: a carousel of home previews over a row of
/// Цайвар / Бараан / Систем swatches. A choice applies at once; undo returns
/// to the theme the sheet opened with.
class ThemeSelectorSheet extends StatefulWidget {
  const ThemeSelectorSheet({
    super.key,
    required this.selection,
    required this.topInset,
  });

  final ValueNotifier<AppTheme> selection;

  /// Status-bar height. Modal sheets strip it from MediaQuery, so the caller
  /// passes it in to keep the sheet's top edge just below the status bar.
  final double topInset;

  @override
  State<ThemeSelectorSheet> createState() => _ThemeSelectorSheetState();
}

class _ThemeSelectorSheetState extends State<ThemeSelectorSheet> {
  late final AppTheme _initial = widget.selection.value;
  late final PageController _pages = PageController(
    viewportFraction: 0.62,
    initialPage: _initial.index,
  );

  // Set while the carousel moves because of a tap, so the pages it passes on
  // the way don't count as choices.
  bool _programmatic = false;

  AppTheme get _current => widget.selection.value;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _select(AppTheme theme, {bool fromSwipe = false}) {
    if (theme == _current) return;
    HapticFeedback.selectionClick();
    setState(() => widget.selection.value = theme);
    if (!fromSwipe) _scrollTo(theme.index);
  }

  Future<void> _scrollTo(int page) async {
    if (!_pages.hasClients) return;
    _programmatic = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(page);
    } else {
      await _pages.animateToPage(
        page,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
    _programmatic = false;
  }

  @override
  Widget build(BuildContext context) {
    final p = TdboPalette.of(context);
    final changed = _current != _initial;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Padding(
        padding: EdgeInsets.only(top: widget.topInset + 10),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: ColoredBox(
            color: p.bg,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Хаах',
                        icon: Icon(Icons.close_rounded, size: 28, color: p.ink),
                      ),
                    ),
                  ),
                  Expanded(child: _carousel(p)),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 96,
                    child: Stack(
                      children: [
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final t in AppTheme.values)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  child: _Swatch(
                                    theme: t,
                                    selected: t == _current,
                                    onTap: () => _select(t),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 12,
                          top: 8,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: changed ? 1 : 0.3,
                            child: IconButton(
                              onPressed: changed
                                  ? () => _select(_initial)
                                  : null,
                              tooltip: 'Буцаах',
                              icon: Icon(
                                Icons.undo_rounded,
                                size: 26,
                                color: p.ink,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _carousel(TdboPalette p) {
    return LayoutBuilder(
      builder: (context, c) {
        // Phone-shaped cards, 62% of the width, shrunk if the sheet is short.
        var cardW = c.maxWidth * 0.62 - 16;
        var cardH = cardW / 0.47;
        if (cardH > c.maxHeight - 48) {
          cardH = c.maxHeight - 48;
          cardW = cardH * 0.47;
        }
        final radius = BorderRadius.circular(cardW * 0.09);

        return Center(
          child: SizedBox(
            height: cardH + 48,
            child: PageView.builder(
              controller: _pages,
              clipBehavior: Clip.none,
              itemCount: AppTheme.values.length,
              onPageChanged: (i) {
                if (!_programmatic) {
                  _select(AppTheme.values[i], fromSwipe: true);
                }
              },
              itemBuilder: (context, i) {
                final theme = AppTheme.values[i];
                final card = Container(
                  width: cardW,
                  height: cardH,
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(color: p.divider),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: radius,
                    child: switch (theme) {
                      AppTheme.light => const HomePreview(
                        palette: TdboPalette.light,
                      ),
                      AppTheme.dark => const HomePreview(
                        palette: TdboPalette.dark,
                      ),
                      AppTheme.system => const SystemPreview(),
                    },
                  ),
                );

                return AnimatedBuilder(
                  animation: _pages,
                  builder: (context, child) {
                    final page =
                        _pages.hasClients && _pages.position.haveDimensions
                        ? _pages.page!
                        : _initial.index.toDouble();
                    final d = (page - i).abs().clamp(0.0, 1.0);
                    return Opacity(
                      opacity: 1 - d * 0.25,
                      child: Transform.scale(scale: 1 - d * 0.08, child: child),
                    );
                  },
                  child: Center(
                    child: Semantics(
                      button: true,
                      selected: theme == _current,
                      label: '${theme.label} загварын харагдац',
                      child: GestureDetector(
                        onTap: () => _select(theme),
                        child: card,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final AppTheme theme;
  final bool selected;
  final VoidCallback onTap;

  static const _lightFill = Color(0xFFF1F2F4);
  static const _darkFill = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3A4556), Color(0xFF141C2A)],
  );

  @override
  Widget build(BuildContext context) {
    final p = TdboPalette.of(context);

    Widget fill() {
      final light = DecoratedBox(
        decoration: BoxDecoration(
          color: _lightFill,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD9DCE1)),
        ),
      );
      const dark = DecoratedBox(
        decoration: BoxDecoration(gradient: _darkFill, shape: BoxShape.circle),
      );
      return switch (theme) {
        AppTheme.light => light,
        AppTheme.dark => dark,
        AppTheme.system => Stack(
          fit: StackFit.expand,
          children: [
            light,
            const ClipRect(clipper: _RightHalf(), child: dark),
          ],
        ),
      };
    }

    return Semantics(
      button: true,
      selected: selected,
      label: '${theme.label} загвар',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 62,
              height: 62,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? p.accent : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: fill(),
            ),
            const SizedBox(height: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? p.ink : p.muted,
              ),
              child: Text(theme.label),
            ),
          ],
        ),
      ),
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
