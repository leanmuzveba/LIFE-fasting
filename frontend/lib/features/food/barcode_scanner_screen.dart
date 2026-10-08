import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ruva_kit.dart';
import '../../core/widgets/sheet.dart';

/// Opens the scanner and returns the barcode digits, or null. Overridden in
/// tests (no camera there).
final barcodeScannerProvider = Provider<Future<String?> Function(BuildContext)>(
  (ref) =>
      (context) => Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const BarcodeScannerScreen())),
);

/// Full-screen camera that reads EAN/UPC product barcodes. Typing the number
/// is always available (no camera, damaged label, bad light).
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA, BarcodeFormat.upcE],
  );
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish(String code) {
    if (_done) return;
    _done = true;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(code);
  }

  Future<void> _type() async {
    final code = await showAppSheet<String>(context, (_) => const _TypeBarcodeSheet());
    if (code != null && mounted) _finish(code);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              for (final b in capture.barcodes) {
                final v = b.rawValue;
                if (v != null && RegExp(r'^\d{8,14}$').hasMatch(v)) return _finish(v);
              }
            },
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l.scanCameraError,
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: AppColors.white),
                ),
              ),
            ),
          ),
          // Viewfinder frame.
          IgnorePointer(
            child: Center(
              child: Container(
                width: 280,
                height: 170,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.accent, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      RoundIconButton(
                        icon: Icons.close,
                        onTap: () => Navigator.of(context).pop(),
                        tooltip: l.back,
                        size: 44,
                        background: AppColors.white,
                        foreground: AppColors.text,
                      ),
                      const Spacer(),
                      RoundIconButton(
                        icon: Icons.flashlight_on_outlined,
                        onTap: _controller.toggleTorch,
                        tooltip: l.scanTorch,
                        size: 44,
                        background: AppColors.white,
                        foreground: AppColors.text,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(header: true, child: Text(l.scanTitle, style: AppText.title.copyWith(fontSize: 18))),
                      const SizedBox(height: 6),
                      Text(l.scanHint, style: AppText.small),
                      const SizedBox(height: 14),
                      PrimaryButton(label: l.scanType, light: true, icon: Icons.keyboard_outlined, onPressed: _type),
                    ],
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

class _TypeBarcodeSheet extends StatefulWidget {
  const _TypeBarcodeSheet();

  @override
  State<_TypeBarcodeSheet> createState() => _TypeBarcodeSheetState();
}

class _TypeBarcodeSheetState extends State<_TypeBarcodeSheet> {
  final _code = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _code.text.replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^\d{8,14}$').hasMatch(v)) return setState(() => _error = context.l10n.scanInvalid);
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Gap16Column(
      children: [
        Semantics(header: true, child: Text(l.scanType, style: AppText.title)),
        RuvaTextField(
          controller: _code,
          label: l.scanNumber,
          bold: true,
          autofocus: true,
          keyboardType: TextInputType.number,
          errorText: _error,
        ),
        PrimaryButton(label: l.scanLookUp, onPressed: _submit),
      ],
    );
  }
}
