import 'package:flutter/material.dart';

abstract final class AppColors {
  static const accent = Color(0xFFCA936B);

  /// Dark brown frosted-glass fill (brown @ 64%) used by pills and icon buttons.
  static const glass = Color(0xA32D1C10);

  /// Hairline border on glass surfaces (white @ 24%).
  static const glassBorder = Color(0x3DFFFFFF);

  static const mapLabelText = Color(0xFFE0E0E0);
  static const calloutCard = Color(0xFF4C231A);

  /// Inset cards inside glass panels (black @ 16%) and their input fields (24%).
  static const panelCard = Color(0x29000000);
  static const panelField = Color(0x3D000000);
  static const panelSubtitle = Color(0xFFCCCCCC);
  /// Apartment plan card background (beige).
  static const apartmentCard = Color(0xFFDDD1C3);
  static const unitChip = Color(0xFF453C37);

  /// Dark scrim behind modals (black @ 80%) and the register form panel (brown @ 48%).
  static const scrim = Color(0xCC000000);
  static const formPanel = Color(0x7A2D1C10);

  /// Text field fill (white @ 4%) and error outline.
  static const fieldFill = Color(0x0AFFFFFF);
  static const fieldError = Color(0xFFE5484D);

  /// Halo ring around range-slider thumbs (#D3AC87 @ 40%).
  static const sliderHalo = Color(0x66D3AC87);
}
