import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:lumina/core/theme/theme_colors.dart';

/// Интерактивная 3D-модель человека для страницы упражнения.
///
/// Фигуру можно вращать пальцем и приближать. Анимация подбирается
/// автоматически под группу мышц (руки — удар, ноги — бег и т.д.).
/// Модель загружается из ассетов приложения — работает без интернета.
///
/// Почему `activeGestureInterceptor: false`:
/// пакет при загрузке модели по умолчанию исполняет несколько тяжёлых
/// обфусцированных JS-блоков (gesture interceptor), и если один из них
/// падает — событие `onLoad` не доходит до Flutter, и спиннер крутится
/// вечно. Для карточки 3D-модели интерцептор не нужен (касания и так
/// обрабатываются внутри WebView), поэтому отключаем его — загрузка
/// становится стабильной.
class Muscle3DViewer extends StatefulWidget {
  final Color highlightColor;
  final IconData muscleIcon;
  final String muscleName;
  final double height;

  const Muscle3DViewer({
    super.key,
    required this.highlightColor,
    required this.muscleIcon,
    required this.muscleName,
    this.height = 260,
  });

  @override
  State<Muscle3DViewer> createState() => _Muscle3DViewerState();
}

class _Muscle3DViewerState extends State<Muscle3DViewer> {
  static const String _modelPath = 'assets/3d_models/mannequin.glb';

  // Не final — при повторной попытке создаём новый контроллер
  // (старый уже «убит» пакетом вместе с dispose старого WebView).
  Flutter3DController _controller = Flutter3DController();
  Timer? _timeout;
  bool _loaded = false;
  bool _failed = false;
  String _errorMessage = '';
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _startTimeout();
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  /// Страховка: если ни `onLoad`, ни `onError` не пришли за 15 секунд,
  /// показываем запасной экран вместо бесконечного спиннера.
  void _startTimeout() {
    _timeout?.cancel();
    _timeout = Timer(const Duration(seconds: 15), () {
      if (mounted && !_loaded && !_failed) {
        setState(() {
          _failed = true;
          _errorMessage = 'Модель не успела загрузиться';
        });
      }
    });
  }

  void _retry() {
    _timeout?.cancel();
    setState(() {
      _attempt++;
      _loaded = false;
      _failed = false;
      _errorMessage = '';
      _controller = Flutter3DController();
    });
    _startTimeout();
  }

  /// Подбирает анимацию манекена под группу мышц.
  /// Ноги проверяются первыми: «бицепс бедра» — это мышца ноги, не руки.
  String _animationForMuscle(String muscle) {
    final m = muscle.toLowerCase();
    if (m.contains('ног') ||
        m.contains('ягод') ||
        m.contains('бедр') ||
        m.contains('икр')) {
      return 'run';
    }
    if (m.contains('пресс') || m.contains('кор') || m.contains('живот')) {
      return 'dash';
    }
    if (m.contains('груд') ||
        m.contains('спин') ||
        m.contains('плеч') ||
        m.contains('бицеп') ||
        m.contains('трицеп') ||
        m.contains('рук')) {
      return 'fight_punch';
    }
    return 'idle';
  }

  Future<void> _onModelLoaded(String address) async {
    if (!mounted) return;
    _timeout?.cancel();
    setState(() {
      _loaded = true;
      _failed = false;
    });
    // Модель готова: включаем анимацию под группу мышц и медленное вращение.
    // Сначала узнаём, какие анимации реально есть в модели, — иначе
    // воспроизведение несуществующей анимации может «уронить» WebView.
    try {
      final available = await _controller.getAvailableAnimations();
      if (!mounted) return;
      final desired = _animationForMuscle(widget.muscleName);
      final animationName = available.contains(desired)
          ? desired
          : (available.isNotEmpty ? available.first : null);
      if (animationName != null) {
        _controller.playAnimation(animationName: animationName, loopCount: 0);
      }
      _controller.startRotation(rotationSpeed: 9);
    } catch (e) {
      // Модель загружена, но анимацию запустить не удалось — не критично.
      debugPrint('⚠️ 3D animation error: $e');
      if (mounted) setState(() {});
    }
  }

  void _onModelError(String error) {
    if (!mounted) return;
    setState(() {
      _failed = true;
      // Не показываем сырые длинные JS-ошибки — только короткую понятную.
      _errorMessage = error == 'Failed to load'
          ? ''
          : (error.length > 60 ? error.substring(0, 60) : error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final color = widget.highlightColor;

    return Container(
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 1.1,
          colors: [
            color.withValues(alpha: 0.30),
            color.withValues(alpha: 0.10),
            tc.card,
          ],
          stops: const [0, 0.55, 1],
        ),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ─── 3D-модель (Key меняется при повторе — пересоздаёт WebView) ───
          Positioned.fill(
            child: _failed
                ? _buildFallback(tc)
                : Flutter3DViewer(
                    key: ValueKey('muscle3d_$_attempt'),
                    src: _modelPath,
                    controller: _controller,
                    activeGestureInterceptor: false,
                    progressBarColor: color,
                    onLoad: _onModelLoaded,
                    onError: _onModelError,
                  ),
          ),

          // ─── Индикатор загрузки ───
          if (!_loaded && !_failed)
            Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: color,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),

          // ─── Бейдж целевой мышцы ───
          if (_loaded || _failed)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.55)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.muscleIcon, size: 13, color: color),
                    const SizedBox(width: 6),
                    Text(
                      widget.muscleName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ─── Подсказка: вращай модель ───
          if (_loaded)
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pan_tool_alt_outlined,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Вращай модель пальцем',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallback(ThemeColors tc) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: widget.highlightColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.muscleIcon,
                size: 28, color: widget.highlightColor),
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage.isNotEmpty
                ? '3D-модель: $_errorMessage'
                : '3D-модель не загрузилась',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tc.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _retry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.highlightColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: widget.highlightColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded,
                      size: 15, color: widget.highlightColor),
                  const SizedBox(width: 6),
                  Text(
                    'Попробовать снова',
                    style: TextStyle(
                      color: widget.highlightColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
