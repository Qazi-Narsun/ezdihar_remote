import 'dart:ui';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Small glass pill used for hints, result counts and errors, with an optional
/// action button.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.icon,
    this.action,
    this.onAction,
  });

  final String label;
  final IconData? icon;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final radius = BorderRadius.circular(40);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 8, 8),
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: radius,
            border: Border.all(color: AppColors.glassBorder, width: 0.48),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label, style: appText(strings, 16, FontWeight.w400))),
              if (action != null)
                TextButton(
                  onPressed: onAction,
                  child: Text(
                    action!,
                    style: appText(strings, 14, FontWeight.w500, color: AppColors.accent),
                  ),
                )
              else
                const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
