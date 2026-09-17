# GitJournal Visual System Upgrade — R&D Report

**Status:** Research only — no code changes made.
**Scope:** Visual/design system layer only. App architecture, features, and the product roadmap ("the plan") are treated as fixed and out of scope, except where the current visual approach is entangled with state management and must be touched to be fixed safely.

---

## 1. Executive Summary

GitJournal's Flutter *build tooling* is already current (Flutter ≥3.47, Dart ≥3.13, recently bumped per git history). The problem isn't the framework version — it's that the **visual layer was never migrated off Flutter's legacy Material 2 system**, and it grew organically with no design tokens, no component library, and three overlapping icon systems.

The right fix is **not** a rewrite and **not** adopting a third-party UI kit (Cupertino-style kits, shadcn-style kits, etc.). It's:

1. Turn on **Material 3** properly (it's explicitly disabled today) using Flutter's own token system (`ColorScheme.fromSeed`, `ThemeExtension`), not a wholesale replacement.
2. Add a **thin design-tokens layer** GitJournal owns (colors, spacing, radius, typography, motion) so theming stops being 100+ scattered hardcoded hex values.
3. **Consolidate to one icon system.**
4. **Revive the abandoned Widgetbook setup** as a living style guide + visual regression safety net, and add golden tests, so the migration can proceed screen-by-screen without breaking things.
5. Roll it out in **phases, screen by screen**, behind verification at each step — never a big-bang swap.

This keeps every existing feature, route, and user flow untouched; only the paint layer changes.

---

## 2. Current State Audit

### 2.1 Framework & tooling
- Flutter `>=3.47.0`, Dart SDK `>=3.13.0` — modern, was just upgraded (`abfacff`, `c246dc3` in recent history). **Not the bottleneck.**
- State management: **mixed** — `provider` (ChangeNotifier, primary), `flutter_bloc` (declared but barely used), and a **hand-rolled bloc-like pattern** in `lib/folder_listing/bloc/` that doesn't use the `flutter_bloc` package at all. This isn't strictly visual, but the theme/settings values that drive the UI flow through `provider`'s `ChangeNotifier`s (`lib/change_notifiers.dart`, `lib/settings/settings_theme.dart`), so any visual refactor touches this seam.
- Navigation: custom `AppRouter` + `onGenerateRoute` string-based routes (`lib/app_router.dart`). Not modern (`go_router` is the current standard) but functionally fine and **out of scope** for a visual-only upgrade — flagged as a separate, optional future project.

### 2.2 Theming (`lib/themes.dart`)
This is the core of the problem:
- `useMaterial3: false` is **explicitly set** on both light and dark themes. GitJournal is deliberately opted out of Material 3, the design system Flutter has shipped as default since Flutter 3.16 (2023).
- Colors are built with `ColorScheme.fromSwatch(primarySwatch: Colors.green)` — a **deprecated Material 2 API** — then patched with hardcoded hex overrides (`0xFF66bb6a`, `0xff6d4c41`, `0xff212121`, etc.) scattered directly in the theme file.
- Only two static themes exist (`DEFAULT_LIGHT_THEME_NAME`, `DEFAULT_DARK_THEME_NAME`), selected via a `switch` on a string name. No token abstraction, no seed-color derivation, no dynamic/system-color support (Android 12+ "Material You" wallpaper theming is unavailable).
- There is **dead, commented-out code in `lib/app.dart`** (lines ~286–308) referencing `flex_color_scheme`'s `FlexSchemeData`/`FlexSchemeColor` API and a "Toledo purple" custom scheme — evidence a prior contributor considered exactly this kind of upgrade and abandoned it mid-thought. `flex_color_scheme` is not in `pubspec.yaml`.
- No contrast/accessibility validation exists for the current palette (worth checking WCAG AA once tokens are defined).

### 2.3 Icons — three systems in simultaneous use
| System | Package | Files using it |
|---|---|---|
| Material Icons | built into Flutter (`Icons.*`) | 48 files |
| Font Awesome | `font_awesome_flutter` | 13 files |
| Material Community Icons | `community_material_icon` | 1 file |

Three icon languages means inconsistent stroke weight, optical size, and visual rhythm across screens — the single most visible symptom of "old/inconsistent visual system" a user would notice.

### 2.4 Component structure
- `lib/widgets/` is a **flat grab-bag** of ~20 files (`app_bar_menu_button.dart`, `sync_button.dart`, `note_delete_dialog.dart`, etc.) — no atomic-design layering (tokens → atoms → molecules → organisms), no shared primitives (no `GJButton`, `GJCard`, etc.). Each screen tends to build ad hoc `Container`/`Row`/`Column` trees with inline styling rather than composing shared components.
- `lib/screens/` has only 5 top-level screens; most UI actually lives inside `lib/folder_listing/`, `lib/editors/`, `lib/settings/`, `lib/core/views/` — the visual code is spread across feature folders rather than centralized, which is fine architecturally but means a visual-token layer must be adopted consistently across many independent folders, not one place.

### 2.5 Existing (unused) design-system tooling
- **Widgetbook** is already a dev dependency (`lib/main.widgetbook.dart` exists, wired to a real `widgetbook` fork pinned at `ref: upgrade-flutter-3.10`, a stale, non-canonical branch). This is a component-catalog tool (Storybook-equivalent for Flutter) that was set up and then abandoned — no golden/visual tests reference it, and the pinned fork is out of date relative to current Flutter/Widgetbook releases.
- **No golden tests exist anywhere in `test/`.** There is currently no automated way to detect a visual regression.

### 2.6 Internationalization constraint
22 supported locales (`lib/l10n/*.arb`), including **Farsi (`fa`)**, an RTL language. Any new component library or layout primitive introduced must be verified under `Directionality.rtl` — this is a real constraint on the "right visual framework" choice, not a nice-to-have.

### 2.7 Responsive/adaptive layout
Only 7 files use `MediaQuery`/`LayoutBuilder` at all — the app is effectively **phone-only today** with no defined breakpoint system. If tablet/desktop/foldable support is ever wanted, that's a second axis the token/layout system should leave room for, but it is not assumed to be in scope now.

---

## 3. Why Material 3 (not a third-party kit, not a custom-from-scratch system)

Options considered:

| Option | Verdict |
|---|---|
| **Material 3 via Flutter's native theming** (`ColorScheme.fromSeed`, `ThemeExtension`, M3 components) | **Recommended.** Zero new UI-kit dependency, it's what Flutter itself now defaults new apps to, every stock widget already knows how to render it, best long-term support, smallest diff per screen. |
| Third-party Flutter UI kits (e.g. shadcn-flutter-style kits, Fluent-style kits) | Rejected. Would mean re-skinning every screen against a foreign design language, contradicts "keep the plan intact," adds a new dependency with its own upgrade risk, no material benefit over M3 for a Material-native app. |
| Fully custom design system built from `Container`/`CustomPaint` up | Rejected. Massive effort, reinvents accessibility/RTL/platform-adaptive behavior Flutter's Material layer already solves, poor ROI for a note-taking app. |
| `flex_color_scheme` package as the *color engine* on top of M3 | **Recommended as a helper, not a replacement.** It generates full, accessible, harmonized `ColorScheme`s from a couple of seed colors and has built-in support for exactly the kind of scheme the abandoned code in `app.dart` was reaching for. Low risk, small dependency, removes the need to hand-maintain two 100-line `ThemeData` blocks. |
| `dynamic_color` package (Android 12+ Material You wallpaper theming) | **Recommended as an opt-in enhancement** in a later phase — cheap to add once tokens exist, well-loved by users of note apps, purely additive (falls back to the seeded scheme where unsupported). |

**Conclusion:** Flip `useMaterial3: true`, replace `ColorScheme.fromSwatch` with a seed-based `ColorScheme` (optionally generated via `flex_color_scheme`), and layer GitJournal-specific tokens on top via `ThemeExtension`. This is the smallest-risk path that produces a genuinely modern, cohesive visual system.

---

## 4. Proposed Target Architecture

```
lib/design/                      (new)
├── tokens/
│   ├── color_tokens.dart        seed colors, semantic colors (git-diff add/remove,
│   │                            sync-status colors, markdown-syntax colors) as a
│   │                            ThemeExtension<GJColors>
│   ├── spacing_tokens.dart      4/8pt spacing scale as constants
│   ├── radius_tokens.dart       shared corner-radius scale
│   ├── typography_tokens.dart   TextTheme built on M3 type scale + google_fonts
│   └── motion_tokens.dart       M3 duration/curve constants
├── theme.dart                   Themes.light / Themes.dark — assembled from tokens,
│                                 replaces today's lib/themes.dart
└── components/                  (grown incrementally, not a big-bang rewrite)
    ├── buttons/
    ├── cards/
    ├── dialogs/
    └── ...
```

Key points:
- **`ThemeExtension`** is the correct Flutter-native mechanism for GitJournal-specific semantic colors (e.g., git status green/red, sync spinner colors) that don't map to a standard `ColorScheme` role — it replaces the current pattern of hardcoding hex codes ad hoc inside widgets.
- Components are migrated **incrementally into `lib/design/components/`** as each screen is touched — not extracted wholesale up front. Don't pre-build a component library speculatively; build it as the phased screen migration demands it.
- Existing feature folders (`lib/folder_listing`, `lib/editors`, etc.) keep their logic; they just import shared components/tokens instead of inlining styles.

---

## 5. Icon Consolidation Plan

Standardize on **one primary set**. Two reasonable choices:
- **Material Symbols** (`material_symbols_icons` package, variable-weight, the actual current Google icon set — distinct from the older `Icons.*` glyphs) — best visual match for a Material 3 app.
- Or simply keep Flutter's built-in `Icons.*` (M3-compatible already) if minimizing new dependencies is preferred.

Either way:
1. Audit the 13 `font_awesome_flutter` usages — replace with the equivalent Material glyph where one exists; keep Font Awesome **only** for brand/service marks it uniquely provides (e.g. GitHub/GitLab/Bitbucket logos in git-host setup screens) since Material has no equivalents for those.
2. Replace the single `community_material_icon` usage and drop the dependency entirely — no reason to carry a whole package for one icon.
3. Result: one glyph language for generic UI icons + Font Awesome scoped strictly to third-party brand marks.

---

## 6. Safety Net (must exist *before* migrating any screen)

Because there is currently **no golden/visual regression testing**, the migration must start by building the net, not by touching `themes.dart`:

1. **Revive Widgetbook**: move off the stale `devfelipereis/widgetbook` fork pinned to `upgrade-flutter-3.10`, onto the current published `widgetbook` package version compatible with Flutter 3.47+. Catalog the app's key screens/components as use-cases.
2. **Add golden tests** (Flutter's built-in `matchesGoldenFile`, or `alchemist`/`golden_toolkit` for multi-device-size goldens) for the highest-traffic screens first: `home_screen`, `app_drawer`, note editor, settings. Capture goldens **before** any visual change, in both light/dark and at least one RTL locale (`fa`).
3. Wire golden-test execution into CI so any future visual PR shows an explicit diff.

This is what makes "upgrade while keeping the plan intact" actually verifiable rather than a promise.

---

## 7. Phased Migration Plan

Each phase is a small, independently shippable, reviewable chunk. No phase changes app behavior/features — only rendering.

| Phase | Work | Risk |
|---|---|---|
| **0. Safety net** | Widgetbook revival, golden tests on key screens (§6) | Low — additive only |
| **1. Token foundation** | Introduce `lib/design/tokens/*`, `ThemeExtension<GJColors>`, spacing/radius/typography scales. No visual change yet — just extract today's hardcoded values into named tokens with identical output. Verify via goldens (should be pixel-identical). | Low |
| **2. Material 3 color system** | Flip `useMaterial3: true`; replace `ColorScheme.fromSwatch` with `ColorScheme.fromSeed` (optionally via `flex_color_scheme`); re-derive GitJournal's green/brown brand colors as seeds; validate WCAG AA contrast in light+dark. Expect and review visual diffs on every screen via goldens — this is the one phase with a real, intentional visual change. | Medium — this is the visible repaint; needs a full manual pass on real devices, light+dark, +RTL |
| **3. Icon consolidation** | Execute §5. Screen-by-screen icon swap, verified against goldens. | Low–Medium |
| **4. Component modernization** | Screen-by-screen: replace bespoke widgets with M3 stock components where a direct equivalent exists (`NavigationDrawer` for `app_drawer.dart`, `FilledButton`/`FilledButton.tonal` for primary actions, `Card` with M3 elevation tokens, `SegmentedButton` for mode toggles, etc.), extracting genuinely reusable pieces into `lib/design/components/` as you go. Order screens by user traffic: home → folder listing → editor → settings → onboarding. | Medium — largest phase, but sliceable per-screen/per-PR |
| **5. Motion polish** | Adopt M3 motion tokens (`motion_tokens.dart`) for existing transitions; nothing structural. | Low |
| **6. Dynamic color (optional, opt-in)** | Add `dynamic_color` package; let Android 12+ users opt into wallpaper-derived theming, falling back to the seeded scheme everywhere else. | Low — purely additive, feature-flaggable in Settings |
| **7. Cleanup & docs** | Remove `community_material_icon` dep, delete dead commented-out `flex_color_scheme` sketch in `app.dart` (superseded by the real implementation), write a short `DESIGN.md` documenting the token system for future contributors, keep Widgetbook current in CI. | Low |

Suggested sequencing: Phases 0–1 first (pure infrastructure, no visible change, safe to land immediately). Phase 2 next as its own reviewed PR since it's the one intentional repaint. Phases 3–4 proceed screen-by-screen, each its own PR, so the app is always in a shippable state between them.

---

## 8. Risks & Mitigations

- **Visual regression on 22 locales, especially RTL (`fa`)** → goldens must include an RTL locale from Phase 0 onward; manually spot-check Farsi after Phase 2 and Phase 4.
- **Contrast/accessibility regressions from new seed-derived colors** → validate WCAG AA programmatically (a simple contrast-ratio check script) as part of Phase 2 review, not just eyeballing.
- **Mixed state-management (provider/bloc) makes theme-state plumbing fragile** → don't refactor state management as part of this project; only touch `Settings`/theme-related `ChangeNotifier`s minimally to add any new theme-mode/dynamic-color toggles. Track a full state-management consolidation as a separate, later effort.
- **Stale Widgetbook fork** → resolve dependency/version compatibility before Phase 0 is considered "done"; if the current published `widgetbook` package doesn't support the project's Flutter version cleanly, fall back to golden tests alone and defer Widgetbook.
- **Scope creep into navigation (`go_router`) or full state-management rewrite** → explicitly out of scope; flag as separate future initiatives so this project doesn't balloon past "visual system upgrade."

---

## 9. Dependency Changes Summary

| Action | Package | Why |
|---|---|---|
| Add | `flex_color_scheme` | Generate accessible, harmonized M3 `ColorScheme`s from brand seed colors; finishes what the abandoned code in `app.dart` started |
| Add | `dynamic_color` | Optional Android 12+ wallpaper-based theming (Phase 6, opt-in) |
| Add (optional) | `material_symbols_icons` | Modern Material icon set matching M3 visual language, if not standardizing on built-in `Icons.*` |
| Add (dev) | `golden_toolkit` or `alchemist` | Multi-size/theme golden testing |
| Update | `widgetbook` | Move off the stale pinned fork/branch onto a current compatible release |
| Remove | `community_material_icon` | Single usage, replace with primary icon set |
| Keep, scope down | `font_awesome_flutter` | Restrict to brand/service icons only (git hosts) |

---

## 10. What "Keeping the Plan Intact" Means Here

- No screens, routes, or features are added, removed, or behaviorally changed.
- No navigation/state-management architecture changes bundled in.
- Every phase ships independently and is revertible.
- The existing brand colors (green primary, brown secondary) are **preserved as seed colors**, not replaced — the visual identity carries over, only the system generating consistent tones/elevations/states around them is modernized.
- Golden tests exist specifically so "visual upgrade" can be proven not to have silently altered anything else.

---

## 11. Suggested Next Step

If this direction looks right, the next concrete deliverable would be Phase 0 (Widgetbook revival + golden test baseline) as its own PR — it's pure safety-net infrastructure, has zero visual or behavioral effect, and unblocks everything after it. Nothing in this document has been implemented yet; this is the research/plan only, per your request.
