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
  aerial image (placeholder for 360 frames); reset button (bottom-end) is the Restart
  button: pops the stack to the first page (`InitialScreen`). Filter state is held locally (no unit data yet).
  Assets in `assets/images/masterplan/`.
- Masterplan building buttons: one box button per building on the upper lane of
  the aerial photo (22 slots, positions in `_laneCentres` on the 2000x1147
  photo grid, inside `RotatingView` so they move with the image). Types/counts
  come from `assets/data/building_details.json` via `BuildingType.loadAll()`
  (`lib/data/building_data.dart`); ids are generated (A01..A05, B01..B15,
  C01, C02). The slot -> type mapping (`_typeCSlots`, then A, then B) is a
  placeholder. Tap opens `BuildingDetailScreen`.
- `BuildingDetailScreen` (Figma 81:2 panel open, 225:184 panel closed): exterior
  photo + floor outline SVGs on a 1920x1081 canvas, info panel (X closes, info
  button bottom-start reopens), rotate buttons cycle `_frames` (one image for now; floor
  outlines only on frame 0; no zoom/slide, image covers the screen) and are hidden
  while a floor is selected, Restart pops to the first page.
- Floor selection (Figma 35:2647): the floor outline SVGs are tappable (outline i
  = floor i+1; tap empty space clears). Selected floor swaps the info panel for
  "Floor Details" and opens the `_ApartmentsPanel` (bottom-centre): a drag-scrollable row
  of image-only cards, one per apartment type of the building, loaded from
  `assets/images/apartments/<type id lower-case>.png` (1br..4br; currently copies
  of the placeholder plan, replace with real plans). Floor Details X only
  collapses the panel (info button reopens); Apartments X clears the selection.
- Apartment details (Figma 59:454): tapping an apartment card replaces both panels with
  `_ApartmentDetailsPanel` (bottom-start: floor, type, plan image, Brochure / Register
  Interest placeholders; no Availability, no per-apartment size data yet). Its X clears
  the apartment and brings the panels back.
- Register Interest (Figma 41:3055 form, 100:17 thank-you; `lib/screens/register_interest_screen.dart`):
  the apartment details Register Interest button calls `RegisterInterestScreen.open(context)`, a
  transparent modal route with the "Your Information" form (name/email/phone validated, nothing
  sent anywhere yet). On submit it pushes `InterestRegisteredScreen` (blurred exterior, logo,
  Restart Experience = popUntil first, dismissible toast top-end). Assets in `assets/images/register/`.
- Convention: every Restart button on a screen (this and future ones) does
  `Navigator.popUntil((r) => r.isFirst)`, not a local state reset.
  Assets in `assets/images/building/`.
- `RotatingView` (`lib/widgets/rotating_view.dart`) is the shared slide/zoom
  stand-in for 360 frames. `GlassIconButton` takes `padding` for a pill with
  icon + label.

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
- Always make code/file changes with direct edits (the Edit/Write tools), never
  with ad-hoc scripts (Python, sed, PowerShell rewrites, etc.).
- Run `flutter analyze` before finishing.

## Keep this file current
When a screen, shared widget, token or convention is added, update the sections above.
