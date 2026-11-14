import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_button.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Экран прослушивания: пульсирующая кнопка «стоп», таймер записи и текст,
/// который распознаётся на лету.
class VoiceFoodListeningView extends StatefulWidget {
  const VoiceFoodListeningView({
    super.key,
    required this.duration,
    required this.usingOnDevice,
    required this.partialText,
    required this.onStop,
  });

  final Duration duration;

  /// Распознаём на телефоне — тогда показываем живой текст речи.
  final bool usingOnDevice;
  final ValueListenable<String> partialText;
  final VoidCallback onStop;

  @override
  State<VoiceFoodListeningView> createState() => _VoiceFoodListeningViewState();
}

class _VoiceFoodListeningViewState extends State<VoiceFoodListeningView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // При отключённых анимациях кнопка просто стоит на месте.
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulseController.stop();
    } else if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Column(
      children: [
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + (_pulseController.value * 0.15);
            final alpha = 0.25 - (_pulseController.value * 0.15);
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 90 * scale,
                  height: 90 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tc.green.withValues(alpha: alpha.clamp(0.0, 1.0)),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onStop,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: tc.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: tc.green.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.stop_rounded,
                      color: Colors.black,
                      size: 36,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        Text(
          AppLocalizations.of(
            context,
          )!.voiceFoodListening(_formatTimer(widget.duration)),
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: tc.text,
          ),
        ),
        const SizedBox(height: 6),
        // Пока человек говорит, показываем распознаваемый текст вместо примера.
        ValueListenableBuilder<String>(
          valueListenable: widget.partialText,
          builder: (context, partial, _) {
            final live = widget.usingOnDevice ? partial.trim() : '';
            return Text(
              live.isNotEmpty
                  ? '«$live»'
                  : AppLocalizations.of(context)!.voiceFoodExample,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: live.isNotEmpty ? tc.text : tc.textSecondary,
                fontWeight: live.isNotEmpty ? FontWeight.w600 : FontWeight.w500,
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        AppButton(
          text: AppLocalizations.of(context)!.voiceDoneRecognize,
          onPressed: widget.onStop,
        ),
      ],
    );
  }

  static String _formatTimer(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
