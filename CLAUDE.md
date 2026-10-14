# Ezdihar Remote (Mashael Al Fursan)

Flutter app implementing the Figma file
`7U3uK1v7FRA0dMmKdOSF97` (Ezdihar _ Mashael Al Fursan). Designs are authored on a
1920x1081 canvas (landscape tablet/desktop), Arabic (RTL) is the default locale.

**Target device:** Android tablet, 1920x1200 (16:10), landscape only, fullscreen. `main()` locks
landscape + `SystemUiMode.immersiveSticky`; the manifest uses `sensorLandscape`. Figma canvases
(1920x1081) are scaled with `BoxFit.cover`, so ~5% of the canvas width is cropped per side at 16:10:
keep important content inside x = 100..1820 of the canvas.

**One canvas for every screen:** `AppCanvas` (`lib/widgets/app_canvas.dart`, mounted in
`MaterialApp.builder` around everything) lays the whole app out on a fixed 1920x1200 logical canvas
(1920 wide like the Figma frames, so sizes in code are Figma pixels) and scales it uniformly to the
screen, so every 16:10
resolution/density shows the identical layout; other aspects are letterboxed (`AppColors.letterbox`),
never reflowed. System text scaling is ignored. All logical sizes in code are canvas pixels: never
size things from the real screen or `devicePixelRatio`. `test/app_canvas_test.dart` checks every
screen is identical and text does not overlap at 1280x800 / 1920x1200 / 2560x1600 x 1, 1.5, 2.

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
6. Before writing/replacing a screen, read "Intentional overrides of the Figma design" below:
   the screenshot is NOT the target where an override applies. Update existing screens by
   editing them (new visuals in, overrides kept), never by regenerating the whole file.

## Project map
- `lib/screens/` one file per screen. `lib/widgets/` reusable pieces.
  `lib/theme/app_colors.dart` colour tokens. `lib/l10n/app_strings.dart` strings.
- Reusable: `OverlayBackground` (image + tint/gradient), `PillButton`,
  `LanguageToggle`, `GlassIconButton`, `BrandTitle`, `MapPin`.
- Flow: `InitialScreen` -> (Start Journey, `Navigator.push`) -> `CityContextScreen`
  -> (tap project logo card) -> `MasterplanScreen`; back button pops.
- `MasterplanScreen` (Figma 24:1403 + Filters 49:5630 + Gallery 49:6205): bottom nav
  = Filters|Gallery tabs; rotate-left / rotate-right buttons sit at the screen sides,
  vertically centred (Figma 225:542 / 225:526, as on the building screen). Tabs are mutually exclusive
  panel toggles (tap active tab or X closes). Rotate buttons slide the zoomed
  aerial image (placeholder for 360 frames); reset button (bottom-end) is the Restart
  button: pops the stack to the first page (`InitialScreen`). Filter state is held locally (no unit data yet).
  Assets in `assets/images/masterplan/`.
- Masterplan building buttons: one box button per building on the upper lane of
  the aerial photo (22 slots, positions in `_laneCentres` on the 2000x1147
  photo grid, inside `RotatingView` so they move with the image). Types/counts
  come from `assets/data/building_details.json` via `BuildingType.loadAll()`
  (`lib/data/building_data.dart`), which also attaches each type's floors
  (`assets/data/floor_details.json`, `FloorDetails`, GF..6F bottom to top) and apartment
  types (`assets/data/apartment_details.json`, `ApartmentDetails`: one area + availability per
  unit type). The three JSON files mirror the project sheet's Building / Floor / Apartment
  tabs; values are copied as they are (C's GF has 0 apartments, A's floor areas don't sum to
  the building total). Ids are generated (A01..A05, B01..B15,
  C01, C02). The slot -> type mapping (`_typeCSlots`, then A, then B) is a
  placeholder. Tap opens `BuildingDetailScreen`.
- `BuildingDetailScreen` (Figma 81:2 panel open, 225:184 panel closed): exterior
  photo + floor outline SVGs on a 1920x1081 canvas, info panel (X closes, info
  button bottom-start reopens), rotate buttons cycle `_frames` (one image for now; floor
  outlines only on frame 0; no zoom/slide, image covers the screen) and are hidden
  while a floor is selected, Restart pops to the first page.
- Floor selection (Figma 35:2647): the floor data is the source of truth (the photo is
  obsolete). The selection indexes the type's floors top first (6F..GF); the floor stepper
  and arrow keys cover every floor in the data. Outline SVG i (top to bottom) is tappable as
  floor i; floors without an outline (GF on the current photo) are reached with the stepper;
  tap empty space clears. Floors are labelled everywhere (title, breadcrumb, stepper, tooltips,
  panels, masterplan floor filter) with the sheet's names via `AppStrings.floorName` /
  `floorNameOfLevel`: English "GF", "1F".."6F", Arabic "الأرضي", "ط1".."ط6". Selected floor swaps
  the info panel for "<floor> Details" (`floorDetailsTitle`: that floor's apartments, types and
  area) and opens the `_ApartmentsPanel`
  (bottom-centre): a drag-scrollable row of cards (plan + bedrooms label), one per apartment
  type on that floor (hidden entirely on a floor with no apartments, e.g. type C's GF), loaded from
  `assets/images/apartments/<type id lower-case>.png` (1br..4br; currently copies
  of the placeholder plan, replace with real plans). Floor Details X only
  collapses the panel (info button reopens); Apartments X clears the selection.
- Apartment details (Figma 59:454): tapping an apartment card replaces both panels with
  `_ApartmentDetailsPanel` (bottom-start: floor, type, area, availability from
  `apartment_details.json`, plan image, Brochure / Register Interest placeholders; availability is a
  badge: green "Available" 59:520 / red "Not Available" 221:35, `_AvailabilityRow`). Its X clears
  the apartment and brings the panels back.
- Brochure: the apartment details Brochure button calls `BrochureScreen.open(context)`
  (`lib/screens/brochure_screen.dart`), a transparent full-screen modal showing
  `assets/pdfs/brochure.pdf` via `pdfx` (`PdfView`, portrait page centred in a padded, bordered frame sized to the page aspect, swipe + start/end arrow
  buttons, pinch zoom, page counter, X closes).
- Register Interest (Figma 41:3055 form, 100:17 thank-you; `lib/screens/register_interest_screen.dart`):
  the apartment details Register Interest button calls `RegisterInterestScreen.open(context)`, a
  transparent modal route with the "Your Information" form (name/email/phone validated, nothing
  sent anywhere yet). On submit it pushes `InterestRegisteredScreen` (blurred exterior, logo,
  Restart Experience = popUntil first, dismissible toast top-end). Assets in `assets/images/register/`.
- Convention: every Restart button on a screen (this and future ones) ends in
  `Navigator.popUntil((r) => r.isFirst)`, not a local state reset. Restart buttons on the
  masterplan/building screens go through `confirmRestart(context)` (`restart_dialog.dart`);
  the thank-you screen restarts directly (it auto-restarts after 30s).
  Assets in `assets/images/building/`.
- UX layer (added after the UX review):
  - `IdleReset` (`lib/widgets/idle_reset.dart`, mounted in `MaterialApp.builder` with the app
    `navigatorKey`): 90s without input off the first page -> "Still there?" 15s countdown ->
    `popUntil(first)`. `LocaleFade` cross-fades on language change (state is kept).
  - Masterplan: building buttons have a 64px touch target, hover/press feedback, a first-visit
    pulse + "Tap a building" hint (`StatusChip`, gone after 12s or first interaction), and are
    dimmed when filtered out (building type, plus floor / size / availability select apartments:
    a building is lit when one of its apartments passes all of them; slider bounds come from the floor
    levels and apartment areas in the data). Chip shows "N of 22 match" / no-match with Clear filters / load error with Retry.
    Drag the map (pans 1:1 with the finger, snaps to the nearest step on release) or hold a
    rotate button (`GlassIconButton.repeatEvery`) to rotate; arrow keys rotate, Esc closes the
    panel. Pinch zooms 1x..3x around the fingers, double-tap toggles 2x at that point / 1x, and
    while zoomed one finger pans freely (no rotation); the zoom wraps the map so building buttons
    stay put and tappable. Rotate buttons/keys and opening a building reset to 1x
    (`RotatingViewState.resetZoom`). Double-tap is detected on raw pointers so building taps
    are not delayed. The Restart button (bottom-end) is an icon + "Restart" pill, as on the building screen.
    The Filters panel always reserves the Clear filters slot so it does not resize (QA #03).
  - Building detail: `_Breadcrumb` (Masterplan > Building > Floor), `_FloorStepper` (up/down
    while a floor is selected, arrow keys too; centre-end, opposite the start-side panels),
    selected floor outline is filled solid orange, the same on every floor (all outline SVGs
    share fill-opacity 0.03, boosted x40), selecting a floor or closing Apartment
    Details reopens a collapsed info panel, floor outlines have tooltips, panels swap with
    `AnimatedSwitcher`. Back/system back/Esc close the topmost layer first (apartment, floor)
    via `PopScope`. Floor Details/Building panel uses a collapse chevron (not X); X still means
    "clear selection" on Apartments and Apartment Details. Apartment cards show a bedrooms
    label; the row fades at scrollable edges and has arrow buttons.
  - Register form: errors show on blur/submit with messages, autofill hints, next/done
    actions, country-code picker (`+966` default), digits-only phone.
  - Shared: `PanelCloseButton` (32px icon, 48px target; use it for every panel X), `FitPanel`
    (first scales a glass panel by the constant `FitPanel.designScale` = canvas / 1920x1081
    Figma frame, so it takes the same share of the screen as in Figma; then
    scales it down to a max screen fraction so the background stays visible; wrap every
    glass panel/toast in it),
    `FadeInAsset`, `StatusChip`, `appText()` (`lib/theme/app_text.dart`). Haptic
    `selectionClick` on glass/pill buttons.
  - Background visibility: initial screen tint is a radial gradient (64% -> 25%), city map
    edge darkening 80% -> 56%, modal scrim 80% -> 64%. `AppColors.textSecondary` (white @ 72%)
    replaces white @ 64% for secondary text.
- `RotatingView` (`lib/widgets/rotating_view.dart`) is the shared slide/zoom
  stand-in for 360 frames. `GlassIconButton` takes `padding` for a pill with
  icon + label.

## Intentional overrides of the Figma design (UX review, 2026-10)
These deviate from Figma ON PURPOSE. When a screen is re-implemented or synced from an updated
Figma, keep every override below unless the user explicitly says to drop it. Do not "fix" them
back to the Figma values, and do not remove the behaviours when regenerating a screen from
`get_design_context`: merge the new visuals into the existing code instead of replacing it.
If Figma changes something an override touches, apply the new design *around* the override
and mention the conflict to the user.

Visual (background visibility):
- Initial screen tint: radial gradient 60% -> 25% black (Figma: flat 64%).
- City map edge darkening: 56% (Figma 80%), centre 15%.
- Modal scrim `AppColors.scrim`: 64% black (Figma 80%).
- Glass panels are capped by `FitPanel` (max ~60% of screen height, gallery 50%, info/apartment
  panels 45% width); apartment details panel spacing is 32 (Figma 48) and plan image 190 high.
- Secondary text on glass uses `AppColors.textSecondary` (white @ 72%), not Figma's 64%.

Sizing / touch:
- All icon buttons >= 48px touch target (rotate buttons 48, not 40; `PanelCloseButton` 48 target
  around the 32px X; building buttons 64px target around the 44px box).

Behaviour (not in Figma):
- `IdleReset` (90s + 15s countdown) and `LocaleFade`; thank-you screen auto-restart (30s) and toast
  auto-dismiss (8s); extra "Browse more units" button on the thank-you screen.
- `confirmRestart` dialog before Restart on masterplan and building screens.
- Masterplan: first-visit pulse + "Tap a building" hint chip, filter-driven dimming and
  match-count / no-match / error chip, "Clear filters" in the Filters panel, drag-to-rotate,
  hold-to-spin, arrow/Esc keys, pinch / double-tap zoom with free pan.
- Building detail: breadcrumb in the header, floor stepper (up/down) while a floor is selected,
  floor tooltips, "Tap a floor" hint, collapse chevron (not X) on the Building/Floor info panel,
  layered Back/Esc via `PopScope`, animated panel swaps, bedrooms label on apartment cards,
  fading edges + arrow buttons on the apartment row.
- Register form: validate-on-blur with error messages, autofill hints, next/done actions,
  country-code picker, digits-only phone, focus first invalid field.
- Haptic + subtle sound on every interaction via `UiFeedback` (`lib/services/ui_feedback.dart`).

## Rules
- Interaction feedback: call `UiFeedback.tap/select/dismiss/step/success/error()` (haptic + a
  quiet sound synthesised in code, no audio assets, `audioplayers`); never call `HapticFeedback`
  directly. `GlassIconButton`, `PillButton`, `PanelCloseButton` and `LanguageToggle` already do
  it; hold-to-spin buttons (`repeatEvery`) stay silent and their callback plays `step`.
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
- CI (`.github/workflows/android.yml`) runs only on a push to the `release` branch (or a manual
  run) and publishes a release (each run uses a build number). "Make a release" = fast-forward
  `release` to the latest `main` and push it. main, PRs and other branches get no CI build:
  verify locally with `flutter analyze` and `flutter test`.

## Keep this file current
When a screen, shared widget, token or convention is added, update the sections above.
