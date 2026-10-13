# Ezdihar Remote (Mashael Al Fursan)

Flutter app implementing the Figma file
`7U3uK1v7FRA0dMmKdOSF97` (Ezdihar _ Mashael Al Fursan). Designs are authored on a
1920x1081 canvas (landscape tablet/desktop), Arabic (RTL) is the default locale.

## Workflow: Figma -> Flutter
1. Load the `figma:figma-design-to-code` skill, then `create_session` (fileKey) and
   `get_design_context` (nodeId with `-` -> `:`, `skillNames: figma-design-to-code`).
2. The returned React/Tailwind is a reference only: translate to Flutter, never copy
   absolute positioning blindly. Use the screenshot as the visual target.
3. Download every static asset (URLs expire in 7 days) into `assets/images/<screen>/`
   with descriptive snake_case names. No Figma URLs in code. Skip duplicates
   (identical SVGs get one file).
4. Check existing code first (below) and reuse before creating anything.
5. Verify against the screenshot: assets present, sizes, positions, RTL.

## Project map
- `lib/screens/` one file per screen. `lib/widgets/` reusable pieces.
  `lib/theme/app_colors.dart` colour tokens. `lib/l10n/app_strings.dart` strings.
- Reusable: `OverlayBackground` (image + tint/gradient), `PillButton`,
  `LanguageToggle`, `GlassIconButton`, `BrandTitle`, `MapPin`.
- Flow: `InitialScreen` -> (Start Journey, `Navigator.push`) -> `CityContextScreen`
  -> (tap project logo card) -> `MasterplanScreen`; back button pops.
- `MasterplanScreen` (Figma 24:1403 + Filters 49:5630 + Gallery 49:6205): bottom nav
  = rotate-left / Filters|Gallery tabs / rotate-right. Tabs are mutually exclusive
  panel toggles (tap active tab or X closes). Rotate buttons slide the zoomed
  aerial image (placeholder for 360 frames); reset button (bottom-end) restores
  the view and closes the panel. Filter state is held locally (no unit data yet).
  Assets in `assets/images/masterplan/`.

## Rules
- Reuse existing widgets/tokens; extend them (new optional param) instead of duplicating.
- Colours go in `AppColors`; no repeated hex literals in screens/widgets.
- Every user-visible string goes in `AppStrings` with both `_en` and `_ar` entries.
- Layout must follow ambient `Directionality` (use `Row`, `EdgeInsetsDirectional`,
  start/end). Exceptions: geography (maps) is physical and must not mirror; flip
  directional icons (e.g. back arrow) in RTL.
- Fonts: Rubik for English, Noto Sans Arabic for Arabic (via `google_fonts`).
- Fixed-canvas screens (maps): lay out on the Figma canvas inside
  `FittedBox(cover)`, keep header/controls outside it in a `SafeArea`.
- New asset folders must be listed in `pubspec.yaml` (`assets/images/` is not recursive).
- Language is app-level state: `LocaleController` (`lib/l10n/locale_controller.dart`)
  is loaded in `main()` and persists the choice via `shared_preferences` (default `ar`).
  Change language only through it (`setLocale`), never with local state.
- Pushed routes get `onLocaleChanged` only; read the current locale from
  `AppStrings.of(context)`, never from a stale constructor value.
- Run `flutter analyze` before finishing.

## Keep this file current
When a screen, shared widget, token or convention is added, update the sections above.
