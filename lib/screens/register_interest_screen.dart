import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';

TextStyle _text(
  AppStrings strings,
  double size,
  FontWeight weight, {
  Color color = Colors.white,
  double spacing = 0,
}) =>
    strings.isArabic
        ? GoogleFonts.notoSansArabic(fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing)
        : GoogleFonts.rubik(fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing);

const _background = 'assets/images/building/exterior.jpg';
const _closeIcon = 'assets/images/masterplan/icon_close.svg';

/// Blurred, darkened exterior photo behind both register screens
/// (Figma 41:3309 / 100:143: black @ 80% over a 14px blur).
class _BlurredScrim extends StatelessWidget {
  const _BlurredScrim({this.showImage = false});

  final bool showImage;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (showImage) Image.asset(_background, fit: BoxFit.cover),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: const ColoredBox(color: AppColors.scrim),
        ),
      ],
    );
  }
}

/// "Your Information" form (Figma 41:3055), shown as a modal over the previous
/// screen. Pops with `true` once submitted; the caller then shows
/// [InterestRegisteredScreen].
class RegisterInterestScreen extends StatefulWidget {
  const RegisterInterestScreen({super.key});

  /// Opens the form and, once it is filled in, the thank-you screen.
  static Future<void> open(BuildContext context) async {
    final navigator = Navigator.of(context);
    final submitted = await navigator.push<bool>(
      PageRouteBuilder<bool>(
        opaque: false,
        pageBuilder: (_, _, _) => const RegisterInterestScreen(),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
    if (submitted == true) {
      await navigator.push(
        PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => const InterestRegisteredScreen(),
          transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
        ),
      );
    }
  }

  @override
  State<RegisterInterestScreen> createState() => _RegisterInterestScreenState();
}

class _RegisterInterestScreenState extends State<RegisterInterestScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _nameValid => _name.text.trim().isNotEmpty;
  bool get _emailValid => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());
  bool get _phoneValid => _phone.text.replaceAll(RegExp(r'\D'), '').length >= 7;

  void _submit() {
    setState(() => _submitted = true);
    if (_nameValid && _emailValid && _phoneValid) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final radius = BorderRadius.circular(32);
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _BlurredScrim(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ClipRRect(
                  borderRadius: radius,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
                    child: Container(
                      width: 408 + 72,
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
                      decoration: BoxDecoration(
                        color: AppColors.formPanel,
                        borderRadius: radius,
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  strings.yourInformation,
                                  style: _text(strings, 24, FontWeight.w500, spacing: -0.24),
                                ),
                              ),
                              IconButton(
                                tooltip: strings.close,
                                onPressed: () => Navigator.of(context).pop(false),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                                icon: SvgPicture.asset(_closeIcon, width: 32, height: 32),
                              ),
                            ],
                          ),
                          const SizedBox(height: 48),
                          _Field(
                            label: strings.yourName,
                            hint: strings.yourNameHint,
                            controller: _name,
                            error: _submitted && !_nameValid,
                            onChanged: (_) => setState(() {}),
                            keyboardType: TextInputType.name,
                          ),
                          const SizedBox(height: 30),
                          _Field(
                            label: strings.emailAddress,
                            hint: strings.emailHint,
                            controller: _email,
                            error: _submitted && !_emailValid,
                            onChanged: (_) => setState(() {}),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 30),
                          _Field(
                            label: strings.contactNumber,
                            hint: strings.phoneHint,
                            controller: _phone,
                            error: _submitted && !_phoneValid,
                            onChanged: (_) => setState(() {}),
                            keyboardType: TextInputType.phone,
                            prefix: '+966',
                          ),
                          const SizedBox(height: 48),
                          GestureDetector(
                            onTap: _submit,
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(80),
                                border: Border.all(color: Colors.white, width: 0.659),
                              ),
                              child: Text(
                                strings.registerInterest,
                                style: _text(strings, 18, FontWeight.w500, spacing: -0.18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    required this.error,
    required this.onChanged,
    required this.keyboardType,
    this.prefix,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool error;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;

  /// Fixed leading text (country code) followed by a divider.
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final muted = Colors.white.withValues(alpha: 0.56);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _text(strings, 16, FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.64), spacing: -0.16),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.fieldFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: error ? AppColors.fieldError : AppColors.glassBorder),
          ),
          child: Row(
            children: [
              if (prefix != null) ...[
                // Phone numbers and codes read left-to-right in both locales.
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(prefix!, style: _text(strings, 18, FontWeight.w400, color: muted, spacing: -0.18)),
                ),
                Container(
                  width: 1,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: AppColors.glassBorder,
                ),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  keyboardType: keyboardType,
                  cursorColor: AppColors.accent,
                  style: _text(strings, 18, FontWeight.w400, spacing: -0.18),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 22),
                    hintText: hint,
                    hintStyle: _text(strings, 18, FontWeight.w400, color: muted, spacing: -0.18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Confirmation after the form is submitted (Figma 100:17): blurred exterior,
/// logo with a Restart Experience button, and a dismissible toast top-end.
class InterestRegisteredScreen extends StatefulWidget {
  const InterestRegisteredScreen({super.key});

  @override
  State<InterestRegisteredScreen> createState() => _InterestRegisteredScreenState();
}

class _InterestRegisteredScreenState extends State<InterestRegisteredScreen> {
  bool _toastVisible = true;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final radius = BorderRadius.circular(40);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _BlurredScrim(showImage: true),
          Center(
            child: SizedBox(
              width: 260,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset('assets/images/register/logo_large.svg'),
                  const SizedBox(height: 40),
                  // Restart: clear the stack and return to the first page.
                  GestureDetector(
                    onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(80),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset('assets/images/building/icon_restart.svg', width: 24, height: 24),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              strings.restartExperience,
                              style: _text(strings, 18, FontWeight.w500, spacing: -0.18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.all(32),
            child: Align(
              alignment: AlignmentDirectional.topEnd,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: !_toastVisible
                    ? const SizedBox.shrink()
                    : ClipRRect(
                        borderRadius: radius,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: AppColors.glass,
                              borderRadius: radius,
                              border: Border.all(color: AppColors.glassBorder, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 426),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        strings.interestRegistered,
                                        style: _text(strings, 20, FontWeight.w500, spacing: -0.2),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        strings.interestRegisteredBody,
                                        style: _text(strings, 16, FontWeight.w400,
                                            color: AppColors.panelSubtitle, spacing: -0.16),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  tooltip: strings.close,
                                  onPressed: () => setState(() => _toastVisible = false),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                                  icon: SvgPicture.asset(_closeIcon, width: 32, height: 32),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
