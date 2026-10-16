import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../l10n/app_strings.dart';
import '../services/player_connection.dart';
import '../services/ui_feedback.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/panel_close_button.dart';
import '../widgets/pill_button.dart';
import '../widgets/status_chip.dart';

/// Pairing with the player on the main screen: a camera window that scans the QR code it shows
/// while no remote is connected, and a manual IP + port bar for when scanning is not possible.
class PairScreen extends StatefulWidget {
  const PairScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PairScreen()),
      );

  @override
  State<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends State<PairScreen> {
  static const _defaultPort = '3737';
  static const _scanSize = 480.0;

  /// The scanner plugin only exists on phones/tablets; elsewhere (desktop, tests) it would throw a
  /// MissingPluginException, so the camera is left out and only the manual bar is offered.
  static final bool _scanSupported =
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  final MobileScannerController? _controller =
      _scanSupported ? MobileScannerController(formats: const [BarcodeFormat.qrCode]) : null;
  final _host = TextEditingController();
  final _port = TextEditingController(text: _defaultPort);
  final _hostFocus = FocusNode();
  final _portFocus = FocusNode();
  bool _paired = false;
  bool _invalidCode = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final saved = PlayerConnection.instance.url;
    if (saved != null) {
      _host.text = saved.host;
      if (saved.hasPort) _port.text = '${saved.port}';
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _host.dispose();
    _port.dispose();
    _hostFocus.dispose();
    _portFocus.dispose();
    super.dispose();
  }

  /// Pairs with [url] and closes; a failure keeps the screen open instead of crashing.
  Future<void> _pair(Uri url) async {
    if (_paired) return;
    _paired = true;
    UiFeedback.success();
    final navigator = Navigator.of(context);
    try {
      await PlayerConnection.instance.connect(url);
    } catch (_) {
      // The link retries on its own; nothing more to do here.
    }
    if (navigator.mounted) navigator.pop();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_paired) return;
    for (final barcode in capture.barcodes) {
      final url = PlayerConnection.parsePairingCode(barcode.rawValue ?? '');
      if (url != null) {
        _pair(url);
        return;
      }
    }
    if (!_invalidCode) {
      UiFeedback.error();
      setState(() => _invalidCode = true);
    }
  }

  // Letters, digits, dots and dashes: an IPv4 address or a host name.
  static final _hostPattern = RegExp(r'^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$');

  String? get _hostError {
    final host = _host.text.trim();
    return host.isNotEmpty && host.length <= 253 && _hostPattern.hasMatch(host) ? null : 'host';
  }

  String? get _portError {
    final port = int.tryParse(_port.text.trim());
    return port != null && port >= 1 && port <= 65535 ? null : 'port';
  }

  void _submit() {
    setState(() => _submitted = true);
    if (_hostError != null) {
      UiFeedback.error();
      _hostFocus.requestFocus();
      return;
    }
    if (_portError != null) {
      UiFeedback.error();
      _portFocus.requestFocus();
      return;
    }
    FocusScope.of(context).unfocus();
    _pair(Uri(scheme: 'ws', host: _host.text.trim(), port: int.parse(_port.text.trim()), path: '/'));
  }

  Widget _cameraError(AppStrings strings, MobileScannerException? error) {
    final denied = error?.errorCode == MobileScannerErrorCode.permissionDenied;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              denied ? strings.cameraPermissionDenied : strings.cameraError,
              textAlign: TextAlign.center,
              style: appText(strings, 18, FontWeight.w400),
            ),
            if (!denied && _scanSupported) ...[
              const SizedBox(height: 20),
              PillButton(
                label: strings.tryAgain,
                width: 180,
                onPressed: () async {
                  try {
                    await _controller?.start();
                  } catch (_) {
                    // Still unavailable; the error view stays.
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _scanner(AppStrings strings) {
    return Container(
      width: _scanSize,
      height: _scanSize,
      decoration: BoxDecoration(
        color: AppColors.panelField,
        border: Border.all(color: AppColors.accent, width: 4),
        borderRadius: BorderRadius.circular(32),
      ),
      clipBehavior: Clip.antiAlias,
      child: _controller == null
          ? _cameraError(strings, null)
          : MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) => _cameraError(strings, error),
              placeholderBuilder: (context) => const SizedBox.shrink(),
            ),
    );
  }

  Widget _field({
    required AppStrings strings,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String? error,
    required List<TextInputFormatter> formatters,
    required TextInputType keyboardType,
    required TextInputAction action,
    required VoidCallback onSubmitted,
  }) {
    final showError = _submitted && error != null;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: action,
      inputFormatters: formatters,
      autocorrect: false,
      enableSuggestions: false,
      textDirection: TextDirection.ltr,
      style: appText(strings, 20, FontWeight.w400),
      cursorColor: AppColors.accent,
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => onSubmitted(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: appText(strings, 18, FontWeight.w400, color: AppColors.textSecondary),
        errorText: showError ? (identical(controller, _host) ? strings.invalidIp : strings.invalidPort) : null,
        errorStyle: appText(strings, 14, FontWeight.w400, color: AppColors.fieldErrorText),
        filled: true,
        fillColor: AppColors.fieldFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.fieldError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.fieldError, width: 2),
        ),
      ),
    );
  }

  Widget _manualBar(AppStrings strings) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 880),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _field(
              strings: strings,
              controller: _host,
              focusNode: _hostFocus,
              label: strings.ipAddress,
              error: _hostError,
              formatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9.-]')),
                LengthLimitingTextInputFormatter(253),
              ],
              keyboardType: TextInputType.url,
              action: TextInputAction.next,
              onSubmitted: () => _portFocus.requestFocus(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: _field(
              strings: strings,
              controller: _port,
              focusNode: _portFocus,
              label: strings.port,
              error: _portError,
              formatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              keyboardType: TextInputType.number,
              action: TextInputAction.done,
              onSubmitted: _submit,
            ),
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.only(top: 0),
            child: PillButton(label: strings.connect, width: 180, height: 60, onPressed: _submit),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.scrim,
      body: SafeArea(
        minimum: const EdgeInsets.all(32),
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(strings.scanScreenCode, style: appText(strings, 32, FontWeight.w500)),
                      const SizedBox(height: 24),
                      _scanner(strings),
                      const SizedBox(height: 20),
                      _invalidCode
                          ? StatusChip(icon: Icons.error_outline, label: strings.notScreenCode)
                          : Text(
                              strings.scanScreenCodeHint,
                              textAlign: TextAlign.center,
                              style: appText(strings, 18, FontWeight.w400, color: AppColors.textSecondary),
                            ),
                      const SizedBox(height: 32),
                      Text(
                        strings.enterManually,
                        style: appText(strings, 20, FontWeight.w500, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      _manualBar(strings),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: PanelCloseButton(
                tooltip: strings.close,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
