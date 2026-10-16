import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../l10n/app_strings.dart';
import '../services/player_connection.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/glass_icon_button.dart';

/// Full-screen modal that shows the project brochure PDF: portrait pages, the
/// current page centred inside a padded, bordered frame. Swipe or use the arrow
/// buttons to change page; pinch to zoom.
class BrochureScreen extends StatefulWidget {
  const BrochureScreen({super.key});

  static const asset = 'assets/pdfs/brochure.pdf';

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        pageBuilder: (_, _, _) => const BrochureScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<BrochureScreen> createState() => _BrochureScreenState();
}

class _BrochureScreenState extends State<BrochureScreen> {
  static const _pageDuration = Duration(milliseconds: 300);
  static const _framePadding = 16.0;
  static const _frameBorder = 2.0;

  late final PdfController _controller = PdfController(
    document: PdfDocument.openAsset(BrochureScreen.asset),
  );

  /// Width / height of the first page, used to size the frame around the page.
  double _aspect = 1 / 1.414;

  @override
  void initState() {
    super.initState();
    _loadAspect();
    // The main screen shows the same brochure page while this modal is open.
    _mirrorPage();
    _controller.pageListenable.addListener(_mirrorPage);
  }

  void _mirrorPage() => PlayerConnection.instance
      .showModal({'kind': 'brochure', 'page': _controller.pageListenable.value});

  Future<void> _loadAspect() async {
    try {
      final document = await _controller.document;
      final page = await document.getPage(1);
      final aspect = page.width / page.height;
      await page.close();
      if (mounted) setState(() => _aspect = aspect);
    } catch (_) {
      // Keep the A4 default; the viewer shows its own error state.
    }
  }

  @override
  void dispose() {
    _controller.pageListenable.removeListener(_mirrorPage);
    PlayerConnection.instance.hideModal();
    _controller.dispose();
    super.dispose();
  }

  void _previous() =>
      _controller.previousPage(duration: _pageDuration, curve: Curves.easeOut);

  void _next() =>
      _controller.nextPage(duration: _pageDuration, curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.scrim,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(112, 32, 112, 72),
              child: Row(
                children: [
                  _arrow(
                    strings,
                    Icons.arrow_back_ios_new,
                    strings.previous,
                    _previous,
                    (page, total) => page > 1,
                  ),
                  Expanded(
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          // Fit the page itself to the space left inside the frame
                          // (border + padding), then grow the frame around it.
                          const inset = _framePadding + _frameBorder;
                          final availW = box.maxWidth - inset * 2;
                          final availH = box.maxHeight - inset * 2;
                          final pageH = availW / availH > _aspect
                              ? availH
                              : availW / _aspect;
                          final pageW = pageH * _aspect;
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white,
                                width: _frameBorder,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(_framePadding),
                              child: SizedBox(
                                width: pageW,
                                height: pageH,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: PdfView(
                                    controller: _controller,
                                    scrollDirection: Axis.horizontal,
                                    backgroundDecoration: const BoxDecoration(
                                      color: Colors.transparent,
                                    ),
                                    builders:
                                        PdfViewBuilders<DefaultBuilderOptions>(
                                          options:
                                              const DefaultBuilderOptions(),
                                          documentLoaderBuilder: (_) =>
                                              const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                    ),
                                              ),
                                          pageLoaderBuilder: (_) =>
                                              const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                    ),
                                              ),
                                          errorBuilder: (_, _) => Center(
                                            child: Text(
                                              strings.brochureError,
                                              style: appText(
                                                strings,
                                                20,
                                                FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  _arrow(
                    strings,
                    Icons.arrow_forward_ios,
                    strings.next,
                    _next,
                    (page, total) => total != null && page < total,
                  ),
                ],
              ),
            ),
            PositionedDirectional(
              top: 24,
              end: 24,
              child: GlassIconButton(
                tooltip: strings.close,
                onPressed: () => Navigator.of(context).pop(),
                padding: const EdgeInsetsDirectional.only(start: 16, end: 24),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.close, color: Colors.white, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      strings.close,
                      style: appText(strings, 18, FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              bottom: 24,
              start: 0,
              end: 0,
              child: Center(
                child: PdfPageNumber(
                  controller: _controller,
                  builder: (_, state, page, total) => Text(
                    total == null ? '' : '$page / $total',
                    style: appText(
                      strings,
                      16,
                      FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Round arrow button that is disabled at the first/last page.
  Widget _arrow(
    AppStrings strings,
    IconData icon,
    String tooltip,
    VoidCallback onTap,
    bool Function(int page, int? total) enabled,
  ) {
    return SizedBox(
      width: 80,
      child: Center(
        child: PdfPageNumber(
          controller: _controller,
          builder: (_, state, page, total) {
            final on = enabled(page, total);
            return Opacity(
              opacity: on ? 1 : 0.3,
              child: GlassIconButton(
                tooltip: tooltip,
                onPressed: on ? onTap : null,
                size: 56,
                child: Icon(icon, color: Colors.white, size: 24),
              ),
            );
          },
        ),
      ),
    );
  }
}
