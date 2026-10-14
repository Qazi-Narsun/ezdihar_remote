import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/ui_feedback.dart';

/// Close (X) button for glass panels. The icon is 32px but the touch target is
/// 48px. Pass [child] to use another icon (e.g. a collapse chevron).
class PanelCloseButton extends StatelessWidget {
  const PanelCloseButton({super.key, required this.tooltip, required this.onPressed, this.child});

  final String tooltip;
  final VoidCallback onPressed;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: () {
        UiFeedback.dismiss();
        onPressed();
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      icon: child ?? SvgPicture.asset('assets/images/masterplan/icon_close.svg', width: 32, height: 32),
    );
  }
}
