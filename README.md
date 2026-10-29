# TDBO theme selector

Flutter prototype of the TDB Online «Өнгө солих» (change colour) page, in the
style of Base's theme picker.

- **Горим** (mode): Цагаан, Хар, Систем, Бараан
- **Өнгө** (colour): the eight current TDBO accent colours
- A skeleton preview of the TDBO home (Figma «Retail», node 74361:5083) shows
  the choice; every tap applies the theme to the app at once.

## Run

```sh
flutter pub get
flutter run -t lib/main_base.dart        # Өнгө солих page
flutter run                              # earlier Revolut-style carousel (v1)
```

Starting theme: `--dart-define=MODE=tsagaan|khar|system|baraan` and
`--dart-define=ACCENT=blue|pink|navy|purple|green|tan|orange|olive`.

## Layout

- `lib/base/color_screen.dart` — the page: preview box, Горим, Өнгө
- `lib/base/tdbo_home.dart` — TDBO home layout, drawn as a skeleton for the preview
- `lib/base/theme_model.dart` — modes, colours and the resolved `Look`
- `lib/main.dart`, `lib/theme_sheet.dart`, `lib/preview_card.dart`,
  `lib/tokens.dart` — the v1 Revolut-style selector

Git tags: `v1-theme-selector`, `v2-base-flow`, `v3-skeleton-preview`.
