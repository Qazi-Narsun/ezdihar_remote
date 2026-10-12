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
  static const unitChip = Color(0xFF453C37);

  /// Halo ring around range-slider thumbs (#D3AC87 @ 40%).
  static const sliderHalo = Color(0x66D3AC87);
}
