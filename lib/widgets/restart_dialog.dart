import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Asks before restarting so a stray tap does not throw away the visitor's
/// place. On confirm, pops the stack to the first page (the Restart convention).
Future<void> confirmRestart(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: AppColors.scrim,
    builder: (_) => const _RestartDialog(),
  );
  if (confirmed == true && context.mounted) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _RestartDialog extends StatelessWidget {
  const _RestartDialog();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final radius = BorderRadius.circular(32);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: radius,
              border: Border.all(color: AppColors.glassBorder, width: 0.8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.restartConfirmTitle, style: appText(strings, 24, FontWeight.w500, spacing: -0.24)),
                const SizedBox(height: 12),
                Text(
                  strings.restartConfirmBody,
                  style: appText(strings, 16, FontWeight.w400, color: AppColors.textSecondary, spacing: -0.16),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: DialogButton(label: strings.cancel, onTap: () => Navigator.of(context).pop(false)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DialogButton(
                        label: strings.restart,
                        filled: true,
                        onTap: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill button used by modal dialogs (outlined, or accent-filled).
class DialogButton extends StatelessWidget {
  const DialogButton({super.key, required this.label, required this.onTap, this.filled = false});

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final radius = BorderRadius.circular(80);
    return Material(
      color: filled ? AppColors.accent : Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: filled ? BorderSide.none : const BorderSide(color: AppColors.glassBorder),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Center(child: Text(label, style: appText(strings, 18, FontWeight.w500, spacing: -0.18))),
        ),
      ),
    );
  }
}
