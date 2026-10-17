import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/food_database/data/open_food_facts_service.dart';
import 'package:lumina/features/food_database/domain/models/food_product.dart';

/// Сканирование штрихкода упаковки и загрузка продукта из Open Food Facts.
///
/// Возвращает [FoodProduct] через `Navigator.pop`, либо `null`, если
/// пользователь закрыл экран.
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage>
    with WidgetsBindingObserver {
  final OpenFoodFactsService _service = OpenFoodFactsService();
  final MobileScannerController _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.itf14,
      BarcodeFormat.code128,
    ],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isLookingUp = false;
  bool _torchOn = false;
  String? _error;
  String? _lastBarcode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.hasCameraPermission) return;
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_isLookingUp) _startCamera();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _controller.stop();
    }
  }

  Future<void> _startCamera() async {
    try {
      await _controller.start();
    } catch (_) {
      // Ошибку камеры покажет errorBuilder самого MobileScanner.
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (mounted) setState(() => _torchOn = !_torchOn);
    } catch (_) {
      if (mounted) {
        showWelmiSnackbar(
          context,
          'Не удалось включить фонарик',
          icon: Icons.flash_off_rounded,
        );
      }
    }
  }

  bool _isRetailBarcode(String value) {
    if (!RegExp(r'^\d+$').hasMatch(value)) return false;
    return value.length == 8 ||
        value.length == 12 ||
        value.length == 13 ||
        value.length == 14;
  }

  Future<void> _handleCapture(BarcodeCapture capture) async {
    if (_isLookingUp) return;

    String? raw;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && _isRetailBarcode(value)) {
        raw = value;
        break;
      }
    }
    if (raw == null) return;

    await _lookup(raw);
  }

  Future<void> _lookup(String barcode) async {
    setState(() {
      _isLookingUp = true;
      _error = null;
      _lastBarcode = barcode;
    });
    await _controller.stop();

    try {
      final product = await _service.fetchByBarcode(barcode);
      if (!mounted) return;

      if (product == null) {
        setState(() {
          _isLookingUp = false;
          _error =
              'Продукт со штрихкодом $barcode не найден в Open Food Facts. '
              'Проверь упаковку или добавь запись вручную.';
        });
        return;
      }

      hapticSuccess();
      Navigator.pop(context, product);
    } on OpenFoodFactsException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLookingUp = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLookingUp = false;
        _error = 'Не удалось загрузить продукт. Проверь интернет и повтори.';
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _error = null;
      _lastBarcode = null;
    });
    await _startCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleCapture,
            fit: BoxFit.cover,
            errorBuilder: (context, error) => _buildCameraError(error),
          ),
          _buildVignette(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const Spacer(),
                _buildScanFrame(),
                const Spacer(),
                _buildBottomPanel(),
              ],
            ),
          ),
          if (_isLookingUp) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildVignette() {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.65),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.8),
            ],
            stops: const [0, 0.28, 0.62, 1],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _circleButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
            tooltip: 'Назад',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Штрихкод',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Наведи камеру на упаковку',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _circleButton(
            icon: _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            onTap: _toggleTorch,
            tooltip: 'Фонарик',
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildScanFrame() {
    return Center(
      child: Container(
        width: 280,
        height: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF8BC98E), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 30,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.search_off_rounded,
                    color: Colors.white70,
                    size: 28,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_lastBarcode != null) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: const Text('Сканировать снова'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            'Поддерживаются EAN-8, EAN-13, UPC-A, UPC-E и Code 128.\n'
            'Данные: Open Food Facts.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 10,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF8BC98E)),
            const SizedBox(height: 16),
            Text(
              'Ищем продукт...',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraError(MobileScannerException error) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_photography_outlined,
                color: Colors.white.withValues(alpha: 0.6),
                size: 44,
              ),
              const SizedBox(height: 16),
              const Text(
                'Камера недоступна',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Разреши доступ к камере в настройках телефона '
                'или введи штрихкод в строке поиска.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
