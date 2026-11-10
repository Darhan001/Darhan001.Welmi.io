import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/features/chat/presentation/widgets/chat_design.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Нижняя панель чата: поле ввода, отправка и голосовое сообщение.
///
/// Вместо поля ввода показывает состояние записи (таймер и живой текст
/// распознавания на телефоне) или ожидание распознавания.
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.isRecording,
    required this.isTranscribing,
    required this.recordDuration,
    required this.usingOnDevice,
    required this.partialText,
    required this.onSend,
    required this.onStartRecording,
    required this.onFinishRecording,
    required this.onNewChat,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final bool isRecording;
  final bool isTranscribing;
  final Duration recordDuration;

  /// Распознаём на телефоне — тогда показываем живой текст речи.
  final bool usingOnDevice;
  final ValueListenable<String> partialText;
  final VoidCallback onSend;
  final VoidCallback onStartRecording;

  /// `send: false` — отменить запись и удалить её.
  final ValueChanged<bool> onFinishRecording;

  /// Начать переписку с чистого листа.
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: ChatDesign.bg,
        border: Border(
          top: BorderSide(
            color: ChatDesign.cardBorder.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: ChatDesign.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: ChatDesign.cardBorder),
          ),
          child: isTranscribing
              ? const _TranscribingRow()
              : isRecording
              ? _RecordingRow(
                  recordDuration: recordDuration,
                  usingOnDevice: usingOnDevice,
                  partialText: partialText,
                  onFinishRecording: onFinishRecording,
                )
              : _ComposeRow(
                  controller: controller,
                  focusNode: focusNode,
                  isLoading: isLoading,
                  onSend: onSend,
                  onStartRecording: onStartRecording,
                  onNewChat: onNewChat,
                ),
        ),
      ),
    );
  }
}

/// Обычный режим: кнопка новой переписки, поле ввода, микрофон, отправка.
class _ComposeRow extends StatelessWidget {
  const _ComposeRow({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
    required this.onStartRecording,
    required this.onNewChat,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;
  final VoidCallback onStartRecording;
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(width: 4),
        Tooltip(
          message: loc.aiNewChat,
          child: GestureDetector(
            onTap: onNewChat,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.auto_awesome_outlined,
                size: 20,
                color: ChatDesign.lime.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: TextInputAction.send,
            maxLines: 5,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            enabled: !isLoading,
            onSubmitted: (_) => onSend(),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: ChatDesign.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: isLoading ? loc.aiHintLoading : loc.aiHintInput,
              hintStyle: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: ChatDesign.textMuted,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 14,
              ),
            ),
          ),
        ),
        Tooltip(
          message: loc.voiceSend,
          child: GestureDetector(
            onTap: isLoading ? null : onStartRecording,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.mic_none_rounded,
                size: 22,
                color: isLoading
                    ? ChatDesign.textMuted
                    : ChatDesign.lime.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: isLoading ? null : onSend,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(4),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isLoading
                  ? ChatDesign.textMuted.withValues(alpha: 0.3)
                  : ChatDesign.lime,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLoading ? Icons.hourglass_empty : Icons.arrow_upward_rounded,
              color: isLoading ? ChatDesign.textMuted : Colors.black,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

/// Режим записи: отмена, таймер, живой текст речи и отправка.
class _RecordingRow extends StatelessWidget {
  const _RecordingRow({
    required this.recordDuration,
    required this.usingOnDevice,
    required this.partialText,
    required this.onFinishRecording,
  });

  final Duration recordDuration;
  final bool usingOnDevice;
  final ValueListenable<String> partialText;
  final ValueChanged<bool> onFinishRecording;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Row(
      children: [
        const SizedBox(width: 4),
        Tooltip(
          message: loc.voiceCancel,
          child: GestureDetector(
            onTap: () => onFinishRecording(false),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(
                Icons.close_rounded,
                size: 22,
                color: ChatDesign.textSecondary,
              ),
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              const _PulsingDot(),
              const SizedBox(width: 10),
              Text(
                _formatDuration(recordDuration),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ChatDesign.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                // При распознавании на телефоне показываем текст по мере речи:
                // пользователь видит, что его слышат.
                child: ValueListenableBuilder<String>(
                  valueListenable: partialText,
                  builder: (context, partial, _) {
                    final live = usingOnDevice ? partial.trim() : '';
                    return Text(
                      live.isNotEmpty
                          ? live
                          : (usingOnDevice
                                ? loc.voiceListening
                                : loc.voiceRecording),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: live.isNotEmpty
                            ? ChatDesign.textPrimary
                            : ChatDesign.textMuted,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => onFinishRecording(true),
          child: Container(
            margin: const EdgeInsets.all(4),
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: ChatDesign.lime,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_upward_rounded,
              color: Colors.black,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  static String _formatDuration(Duration duration) {
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${duration.inMinutes}:$seconds';
  }
}

/// Состояние «распознаю речь» — вместо поля ввода.
class _TranscribingRow extends StatelessWidget {
  const _TranscribingRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ChatDesign.lime,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.voiceTranscribing,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ChatDesign.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Пульсирующая красная точка — индикатор идущей записи.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // При отключённых анимациях точка просто горит.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: 0.35 + 0.65 * _controller.value,
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: ChatDesign.recording,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
