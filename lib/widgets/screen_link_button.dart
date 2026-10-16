import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../screens/pair_screen.dart';
import '../services/player_connection.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'glass_icon_button.dart';

/// Glass pill showing whether the main screen (NarsunPlayer) is connected; tap to scan its QR code
/// and pair (or re-pair with another screen).
class ScreenLinkButton extends StatelessWidget {
  const ScreenLinkButton({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final connection = PlayerConnection.instance;
    return ListenableBuilder(
      listenable: connection,
      builder: (context, _) {
        final (icon, label) = switch (connection.status) {
          PlayerStatus.connected => (
              const Icon(Icons.cast_connected, color: AppColors.availableBadge, size: 24),
              strings.screenConnected,
            ),
          PlayerStatus.connecting => (
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              strings.screenConnecting,
            ),
          PlayerStatus.disconnected => (
              const Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
              connection.url == null ? strings.connectScreen : strings.screenOffline,
            ),
        };
        return GlassIconButton(
          size: 48,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          tooltip: strings.connectScreen,
          onPressed: () => PairScreen.open(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 8),
              Text(label, style: appText(strings, 16, FontWeight.w400)),
            ],
          ),
        );
      },
    );
  }
}
