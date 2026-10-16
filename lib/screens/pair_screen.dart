import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../l10n/app_strings.dart';
import '../services/player_connection.dart';
import '../services/ui_feedback.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/panel_close_button.dart';
import '../widgets/status_chip.dart';

/// Camera view that scans the QR code the player shows on the main screen while no remote is
/// connected, then pairs with it and closes.
class PairScreen extends StatefulWidget {
  const PairScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PairScreen()),
      );

  @override
  State<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends State<PairScreen> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _paired = false;
  bool _invalidCode = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_paired) return;
    for (final barcode in capture.barcodes) {
      final url = PlayerConnection.parsePairingCode(barcode.rawValue ?? '');
      if (url != null) {
        _paired = true;
        UiFeedback.success();
        PlayerConnection.instance.connect(url);
        Navigator.of(context).pop();
        return;
      }
    }
    if (!_invalidCode) {
      UiFeedback.error();
      setState(() => _invalidCode = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.letterbox,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => Center(
              child: Text(strings.cameraError, style: appText(strings, 20, FontWeight.w400)),
            ),
          ),
          // Dim everything but the square the code should sit in.
          IgnorePointer(
            child: Center(
              child: Container(
                width: 520,
                height: 520,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.accent, width: 4),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [BoxShadow(color: AppColors.scrim, spreadRadius: 2000)],
                ),
              ),
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.all(32),
            child: Stack(
              children: [
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: PanelCloseButton(
                    tooltip: strings.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(strings.scanScreenCode, style: appText(strings, 32, FontWeight.w500)),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _invalidCode
                        ? StatusChip(icon: Icons.error_outline, label: strings.notScreenCode)
                        : Text(
                            strings.scanScreenCodeHint,
                            style: appText(strings, 20, FontWeight.w400, color: AppColors.textSecondary),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
