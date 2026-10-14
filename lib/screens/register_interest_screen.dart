import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../widgets/fit_panel.dart';
import '../widgets/panel_close_button.dart';

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
  static const _countryCodes = ['+966', '+971', '+965', '+974', '+973', '+968', '+20', '+44', '+1'];

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  String _countryCode = _countryCodes.first;
  bool _submitted = false;
  bool _closing = false;

  /// Fields the visitor has left at least once: errors show on blur, not
  /// while they are still typing the first time.
  final _touched = <FocusNode>{};

  @override
  void initState() {
    super.initState();
    for (final node in [_nameFocus, _emailFocus, _phoneFocus]) {
      node.addListener(() {
        if (!node.hasFocus && _touched.add(node)) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  bool get _nameValid => _name.text.trim().isNotEmpty;
  bool get _emailValid => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());
  bool get _phoneValid => _phone.text.replaceAll(RegExp(r'\D'), '').length >= 7;

  bool _showError(FocusNode node, bool valid) => (_submitted || _touched.contains(node)) && !valid;

  void _submit() {
    if (_closing) return;
    setState(() => _submitted = true);
    if (_nameValid && _emailValid && _phoneValid) {
      _closing = true;
      Navigator.of(context).pop(true);
    } else {
      // Take the visitor to the first field that needs attention.
      (!_nameValid ? _nameFocus : !_emailValid ? _emailFocus : _phoneFocus).requestFocus();
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
                              PanelCloseButton(
                                tooltip: strings.close,
                                onPressed: () => Navigator.of(context).pop(false),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          _Field(
                            label: strings.yourName,
                            hint: strings.yourNameHint,
                            controller: _name,
                            focusNode: _nameFocus,
                            errorText: _showError(_nameFocus, _nameValid) ? strings.nameError : null,
                            onChanged: (_) => setState(() {}),
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                          ),
                          const SizedBox(height: 24),
                          _Field(
                            label: strings.emailAddress,
                            hint: strings.emailHint,
                            controller: _email,
                            focusNode: _emailFocus,
                            errorText: _showError(_emailFocus, _emailValid) ? strings.emailError : null,
                            onChanged: (_) => setState(() {}),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                          ),
                          const SizedBox(height: 24),
                          _Field(
                            label: strings.contactNumber,
                            hint: strings.phoneHint,
                            controller: _phone,
                            focusNode: _phoneFocus,
                            errorText: _showError(_phoneFocus, _phoneValid) ? strings.phoneError : null,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _submit(),
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.telephoneNumberNational],
                            formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 \-]'))],
                            countryCode: _countryCode,
                            countryCodes: _countryCodes,
                            onCountryCode: (code) => setState(() => _countryCode = code),
                          ),
                          const SizedBox(height: 40),
                          Material(
                            color: AppColors.accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(80),
                              side: const BorderSide(color: Colors.white, width: 0.659),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(80),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _submit();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    strings.registerInterest,
                                    style: _text(strings, 18, FontWeight.w500, spacing: -0.18),
                                  ),
                                ),
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
    required this.focusNode,
    required this.errorText,
    required this.onChanged,
    required this.keyboardType,
    required this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.formatters,
    this.countryCode,
    this.countryCodes = const [],
    this.onCountryCode,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;

  /// Message under the field; non-null also turns the outline red.
  final String? errorText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? formatters;

  /// When set, a country-code picker precedes the text, followed by a divider.
  final String? countryCode;
  final List<String> countryCodes;
  final ValueChanged<String>? onCountryCode;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final muted = Colors.white.withValues(alpha: 0.56);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _text(strings, 16, FontWeight.w400, color: AppColors.textSecondary, spacing: -0.16),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.fieldFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: errorText != null ? AppColors.fieldError : AppColors.glassBorder),
          ),
          child: Row(
            children: [
              if (countryCode != null) ...[
                // Phone numbers and codes read left-to-right in both locales.
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: PopupMenuButton<String>(
                    tooltip: '',
                    color: AppColors.calloutCard,
                    initialValue: countryCode,
                    onSelected: onCountryCode,
                    itemBuilder: (_) => [
                      for (final code in countryCodes)
                        PopupMenuItem(
                          value: code,
                          child: Text(code, style: _text(strings, 16, FontWeight.w400)),
                        ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(countryCode!, style: _text(strings, 18, FontWeight.w400, color: muted, spacing: -0.18)),
                          Icon(Icons.arrow_drop_down, color: muted),
                        ],
                      ),
                    ),
                  ),
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
                  focusNode: focusNode,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  autofillHints: autofillHints,
                  inputFormatters: formatters,
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
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          alignment: AlignmentDirectional.topStart,
          child: errorText == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    errorText!,
                    style: _text(strings, 14, FontWeight.w400, color: AppColors.fieldErrorText),
                  ),
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
  Timer? _toastTimer;
  Timer? _restartTimer;

  @override
  void initState() {
    super.initState();
    _toastTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _toastVisible = false);
    });
    // Nobody is going to tap Restart on an abandoned kiosk: start over.
    _restartTimer = Timer(const Duration(seconds: 30), _restart);
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _restartTimer?.cancel();
    super.dispose();
  }

  /// Restart: clear the stack and return to the first page.
  void _restart() {
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

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
            // As wide as the widest button (at least the logo), so the
            // Restart Experience label stays on one line in both languages.
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: SvgPicture.asset('assets/images/register/logo_large.svg')),
                  const SizedBox(height: 40),
                  Material(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(80),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(80),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _restart();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset('assets/images/building/icon_restart.svg', width: 24, height: 24),
                            const SizedBox(width: 8),
                            Text(
                              strings.restartExperience,
                              maxLines: 1,
                              softWrap: false,
                              style: _text(strings, 18, FontWeight.w500, spacing: -0.18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Back to the building the visitor was browsing.
                  Material(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(80),
                      side: const BorderSide(color: AppColors.glassBorder),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(80),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pop();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        child: Center(
                          child: Text(
                            strings.browseMore,
                            textAlign: TextAlign.center,
                            style: _text(strings, 18, FontWeight.w500, spacing: -0.18),
                          ),
                        ),
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
                    : FitPanel(
                        maxWidthFactor: 0.45,
                        alignment: AlignmentDirectional.topEnd,
                        child: ClipRRect(
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
                                PanelCloseButton(
                                  tooltip: strings.close,
                                  onPressed: () => setState(() => _toastVisible = false),
                                ),
                              ],
                            ),
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
