# GitJournal Design System

Implemented via the **GitJournal Visual Upgrade** Linear project (SHU-5 … SHU-18) on branch `upgrade-flutter-latest`.

## Token system (`lib/design/tokens/`)

| File | Purpose |
|------|---------|
| `color_tokens.dart` | Brand seeds (`gjSeedPrimary`, `gjSeedSecondary`) + legacy named colors |
| `spacing_tokens.dart` | 4/8pt scale: `spacingXs`…`spacingXl` |
| `radius_tokens.dart` | Corner radii: `radiusSm`…`radiusXl` |
| `typography_tokens.dart` | Scaffold for M3 type scale (filled when needed) |
| `motion_tokens.dart` | M3 durations (`durationShort*` / `Medium*` / `Long*`) + curves |

**Adding a token:** put the constant in the matching file, use it from UI code, avoid new raw literals for the same value.

Themes are built in `lib/themes.dart` with `flex_color_scheme` (`FlexThemeData.light/dark`, `useMaterial3: true`).

## Icon policy

- **Primary:** Material `Icons.*`
- **Font Awesome:** removed from app UI (SHU-10). Host logos use image assets, not FA brand glyphs.
- Do not reintroduce mixed icon libraries without a documented exception.

## Widgetbook

Entry: `lib/main.widgetbook.dart` (Widgetbook 3.x from pub.dev).

```bash
flutter pub get
flutter run -t lib/main.widgetbook.dart
# or debug APK
flutter build apk -t lib/main.widgetbook.dart --debug
```

## Golden tests

Baselines live under `test/golden/goldens/`.

```bash
# verify
flutter test test/golden

# update after intentional visual change
flutter test test/golden --update-goldens
```

CI workflow `.github/workflows/goldens.yml` runs verify on PRs and relevant pushes. **Regenerate only when chrome/theme intentionally changed**; unexpected golden failures are regressions, not a reason to blind-update.

## Navigation shell

Primary destinations use Material 3 `NavigationBar` (Notes / Folders / Tags). Settings, Git Terminal, and utility actions live under Settings; repo switcher is the AppBar title menu.
