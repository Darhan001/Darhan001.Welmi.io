import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/services/ai_service.dart';
import 'package:lumina/core/services/speech_output_service.dart';
import 'package:lumina/core/services/voice_recorder_service.dart';
import 'package:lumina/core/widgets/app_snackbar.dart';
import 'package:lumina/core/widgets/voice_messages.dart';
import 'package:lumina/l10n/app_localizations.dart';

// ─── Premium design tokens ────────────────────────────────────
class _Design {
  static const Color bg = Color(0xFF0F0F0F);
  static const Color card = Color(0xFF1A1A1A);
  static const Color cardBorder = Color(0xFF2A2A2A);
  static const Color lime = Color(0xFFD4FF44);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color textMuted = Color(0xFF555555);
  static const double radiusLg = 28;
}

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key, this.initialPrompt});
  final String? initialPrompt;

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final AiService _aiService = AiService();

  final List<_ChatBubble> _messages = [];
  bool _isLoading = false;

  // Голосовые сообщения (запись → распознавание речи → текст в чат)
  final VoiceRecorderService _voice = VoiceRecorderService();
  // Озвучивание ответов AI
  final SpeechOutputService _speech = SpeechOutputService();
  bool _isRecording = false;
  bool _isStartingRecording = false;
  bool _isTranscribing = false;
  // Ответы, которые уже озвучивались: для них кнопка становится «повторить».
  final Set<String> _spokenTexts = {};
  Duration _recordDuration = Duration.zero;
  Timer? _recordTicker;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Сначала восстанавливаем историю, и только потом отправляем стартовый
  /// вопрос (кнопка «Спросить» на экране рецепта). Пока это шло параллельно,
  /// история успевала загрузиться после отправки и добавляла тот же вопрос
  /// вторым сообщением.
  Future<void> _bootstrap() async {
    await _loadHistory();
    if (!mounted) return;
    final prompt = widget.initialPrompt;
    if (prompt != null && prompt.isNotEmpty) {
      await _sendMessage(text: prompt);
    }
  }

  @override
  void dispose() {
    _recordTicker?.cancel();
    if (_isRecording) _voice.cancel();
    _voice.dispose();
    _speech.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    await _aiService.loadChatHistory();
    if (!mounted) return;

    final saved = _aiService.chatHistory;
    // Не перезаписываем уже показанную переписку: иначе загруженная история
    // может задвоить сообщения, отправленные до её окончания.
    if (saved.isNotEmpty && _messages.isEmpty) {
      setState(() {
        _messages.addAll(
          saved.map(
            (m) => _ChatBubble(
              text: m.text,
              isUser: m.role == 'user',
              timestamp: m.timestamp,
            ),
          ),
        );
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage({String? text, bool isVoice = false}) async {
    final message = text ?? _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    HapticFeedback.lightImpact();
    if (text == null) _messageController.clear();
    _focusNode.unfocus();

    setState(() {
      _messages.add(_ChatBubble(text: message, isUser: true, isVoice: isVoice));
      _isLoading = true;
    });
    _scrollToBottom();

    final loc = AppLocalizations.of(context)!;
    String reply;
    try {
      reply = await _aiService.sendChatMessage(message);
    } on AiUnavailableException catch (e) {
      debugPrint('⚠️ Chat unavailable: ${e.reason}');
      reply = loc.aiErrorUnavailable;
    } catch (e) {
      debugPrint('❌ Chat error: $e');
      reply = loc.aiErrorConnection;
    }
    if (!mounted) return;
    setState(() {
      _messages.add(_ChatBubble(text: reply, isUser: false));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  // ─── Голосовые сообщения: запись и распознавание ───────────

  /// Максимум 60 секунд: более длинные записи провайдеры STT
  /// завершают по таймауту, а короткие реплики точнее распознаются.
  static const int _maxVoiceSeconds = 60;

  /// Начинает запись голосового сообщения.
  Future<void> _startRecording() async {
    if (_isRecording || _isTranscribing || _isStartingRecording) return;
    final loc = AppLocalizations.of(context)!;
    HapticFeedback.mediumImpact();

    _isStartingRecording = true;
    try {
      await _voice.start();
    } on VoiceRecordException catch (e) {
      debugPrint('⚠️ $e');
      if (mounted) _showVoiceError(voiceRecordMessage(loc, e));
      return;
    } finally {
      _isStartingRecording = false;
    }
    if (!mounted) return;

    setState(() {
      _isRecording = true;
      _recordDuration = Duration.zero;
    });
    _recordTicker?.cancel();
    _recordTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _recordDuration += const Duration(seconds: 1));
      if (_recordDuration.inSeconds >= _maxVoiceSeconds) {
        _finishRecording(send: true);
      }
    });
  }

  /// Останавливает запись. [send] = false — просто удалить запись.
  Future<void> _finishRecording({required bool send}) async {
    if (!_isRecording) return;
    _recordTicker?.cancel();
    _recordTicker = null;
    HapticFeedback.lightImpact();
    if (mounted) setState(() => _isRecording = false);

    if (!send) {
      await _voice.cancel();
      return;
    }
    Uint8List bytes;
    try {
      bytes = await _voice.stopAndRead();
    } on VoiceRecordException catch (e) {
      debugPrint('⚠️ $e');
      if (mounted) {
        _showVoiceError(AppLocalizations.of(context)!.voiceErrorTranscribe);
      }
      return;
    }
    await _transcribeAndSend(bytes);
  }

  /// Распознаёт аудио и отправляет полученный текст в чат от имени пользователя.
  Future<void> _transcribeAndSend(Uint8List bytes) async {
    setState(() => _isTranscribing = true);
    String? text;
    VoiceTranscriptionFailure? failure;
    try {
      text = await _aiService.transcribeAudio(
        bytes,
        format: _voice.format,
        language: _speechLanguageHint,
      );
    } on VoiceTranscriptionException catch (e) {
      debugPrint('⚠️ $e');
      failure = e.failure;
    }
    if (!mounted) return;
    setState(() => _isTranscribing = false);

    if (text == null || text.trim().isEmpty) {
      _showVoiceError(
        voiceTranscriptionMessage(
          AppLocalizations.of(context)!,
          failure ?? VoiceTranscriptionFailure.emptyResult,
        ),
      );
      return;
    }
    await _sendMessage(text: text, isVoice: true);
  }

  /// Подсказка языка для STT: для ru/en заметно точнее,
  /// для остальных локалей оставляем автоопределение провайдеру.
  String? get _speechLanguageHint {
    final code = _languageCode;
    return (code == 'ru' || code == 'en') ? code : null;
  }

  String get _languageCode => Localizations.localeOf(context).languageCode;

  void _showVoiceError(String message) {
    if (!mounted) return;
    AppSnackbar.error(context, message);
  }

  // ─── Озвучивание ответов ───────────────────────────────────

  /// Убирает markdown-разметку, которую синтезатор прочитал бы вслух.
  static String _plainSpeechText(String text) =>
      text.replaceAll(RegExp(r'[*_#`>]'), '').trim();

  /// Озвучивает сообщение или, если оно уже звучит, останавливает речь.
  Future<void> _toggleSpeech(String text) async {
    final loc = AppLocalizations.of(context)!;
    final plain = _plainSpeechText(text);
    if (_speech.speakingText.value == plain) {
      await _speech.stop();
      return;
    }
    HapticFeedback.selectionClick();
    try {
      await _speech.speak(plain, languageCode: _languageCode);
      _spokenTexts.add(text);
    } on SpeechOutputException catch (e) {
      debugPrint('⚠️ $e');
      if (mounted) AppSnackbar.error(context, loc.ttsErrorUnavailable);
    }
  }

  Future<void> _showVoicePicker() async {
    final loc = AppLocalizations.of(context)!;
    HapticFeedback.lightImpact();
    List<SpeechVoice> voices;
    try {
      await _speech.init();
      voices = await _speech.voicesFor(_languageCode);
    } catch (e) {
      debugPrint('⚠️ TTS voices error: $e');
      if (mounted) AppSnackbar.error(context, loc.ttsErrorUnavailable);
      return;
    }
    if (!mounted) return;
    final selected = _speech.selectedVoice;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _Design.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_Design.radiusLg),
        ),
      ),
      builder: (ctx) {
        final maxHeight = MediaQuery.sizeOf(ctx).height * 0.6;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Text(
                    loc.ttsVoiceSettings,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _Design.textPrimary,
                    ),
                  ),
                ),
                _voiceTile(
                  title: loc.ttsVoiceDefault,
                  subtitle: null,
                  isSelected: selected == null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _speech.selectVoice(null);
                  },
                ),
                if (voices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Text(
                      loc.ttsVoicesEmpty,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _Design.textSecondary,
                      ),
                    ),
                  ),
                for (final voice in voices)
                  _voiceTile(
                    title: voice.name,
                    subtitle: voice.locale,
                    isSelected: voice == selected,
                    onTap: () {
                      Navigator.pop(ctx);
                      _speech.selectVoice(voice);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _voiceTile({
    required String title,
    required String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _Design.textPrimary,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _Design.textSecondary,
              ),
            ),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: _Design.lime)
          : null,
    );
  }

  void _startNewChat() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_Design.radiusLg),
        ),
        backgroundColor: _Design.card,
        title: Text(
          AppLocalizations.of(context)!.aiNewChat,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            color: _Design.textPrimary,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.aiNewChatConfirm,
          style: GoogleFonts.inter(color: _Design.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.of(context)!.drawerCancel,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: _Design.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _speech.stop();
              setState(() {
                _messages.clear();
                _isLoading = false;
              });
              _aiService.startNewChat();
            },
            child: Text(
              AppLocalizations.of(context)!.aiStart,
              style: GoogleFonts.inter(
                color: _Design.lime,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMessages = _messages.isNotEmpty;

    return Scaffold(
      backgroundColor: _Design.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Back button bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: _Design.textPrimary,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: AppLocalizations.of(context)!.ttsVoiceSettings,
                    onPressed: _showVoicePicker,
                    icon: const Icon(
                      Icons.record_voice_over_outlined,
                      color: _Design.textSecondary,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: hasMessages ? _buildChatView() : _buildWelcomeView(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Welcome View (no messages yet) ────────────────────────
  Widget _buildWelcomeView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Glow avatar
                  _buildGlowAvatar(),
                  const SizedBox(height: 24),
                  // Capsule label
                  Text(
                    AppLocalizations.of(context)!.gymtoneTrainer,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: _Design.lime.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Greeting
                  Text(
                    AppLocalizations.of(context)!.aiWelcomeGreeting,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _Design.textPrimary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Suggestion pills
                  _buildSuggestion(AppLocalizations.of(context)!.aiSuggestion1),
                  const SizedBox(height: 10),
                  _buildSuggestion(AppLocalizations.of(context)!.aiSuggestion2),
                  const SizedBox(height: 10),
                  _buildSuggestion(AppLocalizations.of(context)!.aiSuggestion3),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        // Input field
        _buildInputArea(),
      ],
    );
  }

  // ─── Chat View (has messages) ──────────────────────────────
  Widget _buildChatView() {
    return Column(
      children: [
        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: _messages.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length && _isLoading) {
                return _buildTypingIndicator();
              }
              return _buildMessageBubble(_messages[index]);
            },
          ),
        ),
        // Input field
        _buildInputArea(),
      ],
    );
  }

  // ─── Glow Avatar ───────────────────────────────────────────
  Widget _buildGlowAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            _Design.lime.withValues(alpha: 0.2),
            _Design.lime.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.3, 0.7, 1.0],
        ),
      ),
      child: Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _Design.lime.withValues(alpha: 0.1),
            border: Border.all(
              color: _Design.lime.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF75A47F), Color(0xFF5A8A64)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _Design.lime.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'W',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Suggestion Pill ───────────────────────────────────────
  Widget _buildSuggestion(String text) {
    return GestureDetector(
      onTap: () => _sendMessage(text: text),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_Design.card, Color(0xFF222222)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(_Design.radiusLg),
          border: Border.all(color: _Design.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _Design.textPrimary,
          ),
        ),
      ),
    );
  }

  // ─── Message Bubble ────────────────────────────────────────
  Widget _buildMessageBubble(_ChatBubble message) {
    final isUser = message.isUser;

    final bubbleColor = isUser
        ? _Design.lime.withValues(alpha: 0.12)
        : _Design.card;

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
        top: 6,
        bottom: 6,
      ),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF75A47F), Color(0xFF5A8A64)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                border: Border.all(
                  color: isUser
                      ? _Design.lime.withValues(alpha: 0.1)
                      : _Design.cardBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isVoice) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mic_rounded,
                          size: 13,
                          color: _Design.lime.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)!.voiceMessageLabel,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            letterSpacing: 0.4,
                            fontWeight: FontWeight.w700,
                            color: _Design.lime.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  _buildMessageText(message.text, isUser),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: _Design.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all_rounded,
                          size: 12,
                          color: _Design.lime.withValues(alpha: 0.5),
                        ),
                      ] else ...[
                        const SizedBox(width: 8),
                        _buildSpeakButton(message.text),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Кнопка озвучивания ответа AI: «озвучить», «повторить» или «стоп».
  Widget _buildSpeakButton(String text) {
    final loc = AppLocalizations.of(context)!;
    return ValueListenableBuilder<String?>(
      valueListenable: _speech.speakingText,
      builder: (context, speaking, _) {
        final isSpeaking = speaking == _plainSpeechText(text);
        final replay = _spokenTexts.contains(text);
        final tooltip = isSpeaking
            ? loc.ttsStop
            : (replay ? loc.ttsReplay : loc.ttsPlay);
        final icon = isSpeaking
            ? Icons.stop_circle_outlined
            : (replay ? Icons.replay_rounded : Icons.volume_up_rounded);
        return Tooltip(
          message: tooltip,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _toggleSpeech(text),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                icon,
                size: 16,
                color: isSpeaking ? _Design.lime : _Design.textMuted,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageText(String text, bool isUser) {
    final textColor = isUser ? _Design.lime : _Design.textPrimary;

    final theme = TextStyle(
      fontSize: 15,
      height: 1.5,
      color: textColor,
      fontWeight: FontWeight.w500,
    );

    return text.contains('**') || text.contains('_')
        ? RichText(
            text: _parseFormattedText(text, isUser),
            textScaler: MediaQuery.textScalerOf(context),
          )
        : Text(
            text,
            style: theme.copyWith(fontFamily: GoogleFonts.inter().fontFamily),
          );
  }

  TextSpan _parseFormattedText(String text, bool isUser) {
    final baseColor = isUser ? _Design.lime : _Design.textPrimary;
    final italicColor = isUser
        ? _Design.lime.withValues(alpha: 0.7)
        : _Design.textSecondary;

    final spans = <TextSpan>[];
    final regex = RegExp(r'(\*\*(.+?)\*\*|_(.+?)_)');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.5,
              color: baseColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }

      if (match.group(1)?.startsWith('**') == true) {
        spans.add(
          TextSpan(
            text: match.group(2),
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.5,
              color: baseColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: match.group(3),
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.5,
              color: italicColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.5,
            color: baseColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return TextSpan(children: spans);
  }

  // ─── Typing Indicator ──────────────────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(right: 48, top: 6, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8, bottom: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF75A47F), Color(0xFF5A8A64)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 14,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: _Design.card,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: _Design.cardBorder),
            ),
            child: const _TypingDots(dotColor: _Design.lime),
          ),
        ],
      ),
    );
  }

  // ─── Input Area ────────────────────────────────────────────
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: _Design.bg,
        border: Border(
          top: BorderSide(
            color: _Design.cardBorder.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: _Design.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _Design.cardBorder),
          ),
          child: _isTranscribing
              ? _buildTranscribingRow()
              : _isRecording
              ? _buildRecordingRow()
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(width: 4),
                    // New chat button
                    GestureDetector(
                      onTap: _startNewChat,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.auto_awesome_outlined,
                          size: 20,
                          color: _Design.lime.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    // Text field
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        textInputAction: TextInputAction.send,
                        maxLines: 5,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        enabled: !_isLoading,
                        onSubmitted: (_) => _sendMessage(),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _Design.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: _isLoading
                              ? AppLocalizations.of(context)!.aiHintLoading
                              : AppLocalizations.of(context)!.aiHintInput,
                          hintStyle: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: _Design.textMuted,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    // Mic button — голосовое сообщение
                    Tooltip(
                      message: AppLocalizations.of(context)!.voiceSend,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _startRecording,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Icons.mic_none_rounded,
                            size: 22,
                            color: _isLoading
                                ? _Design.textMuted
                                : _Design.lime.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                    // Send button
                    GestureDetector(
                      onTap: _isLoading ? null : () => _sendMessage(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(4),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _isLoading
                              ? _Design.textMuted.withValues(alpha: 0.3)
                              : _Design.lime,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isLoading
                              ? Icons.hourglass_empty
                              : Icons.arrow_upward_rounded,
                          color: _isLoading ? _Design.textMuted : Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ─── Ряд записи голосового ────────────────────────────────

  Widget _buildRecordingRow() {
    final loc = AppLocalizations.of(context)!;
    return Row(
      children: [
        const SizedBox(width: 4),
        Tooltip(
          message: loc.voiceCancel,
          child: GestureDetector(
            onTap: () => _finishRecording(send: false),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(
                Icons.close_rounded,
                size: 22,
                color: _Design.textSecondary,
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
                _formatDuration(_recordDuration),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _Design.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  loc.voiceRecording,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _Design.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _finishRecording(send: true),
          child: Container(
            margin: const EdgeInsets.all(4),
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: _Design.lime,
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

  /// Состояние «распознаю речь» — вместо поля ввода.
  Widget _buildTranscribingRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _Design.lime,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.voiceTranscribing,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _Design.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return AppLocalizations.of(context)!.aiJustNow;
    if (diff.inMinutes < 60) {
      return AppLocalizations.of(context)!.aiMinutesAgo(diff.inMinutes);
    }
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _ChatBubble {
  final String text;
  final bool isUser;
  final bool isVoice;
  final DateTime timestamp;

  _ChatBubble({
    required this.text,
    required this.isUser,
    this.isVoice = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Animated typing dots
class _TypingDots extends StatefulWidget {
  final Color dotColor;

  const _TypingDots({this.dotColor = Colors.white});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
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
      builder: (context, child) {
        return SizedBox(
          width: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [_dot(0.0), _dot(0.2), _dot(0.4)],
          ),
        );
      },
    );
  }

  Widget _dot(double delay) {
    final phase = (_controller.value - delay) * pi;
    final offset = -8 * sin(phase).clamp(-1.0, 1.0);
    return Transform.translate(
      offset: Offset(0, offset > 0 ? 0 : offset),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.dotColor.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Пульсирующая красная точка — индикатор идущей записи
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
  )..repeat(reverse: true);

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
            color: Color(0xFFFF5252),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
