import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina/core/services/ai_service.dart';
import 'package:lumina/core/services/speech_output_service.dart';
import 'package:lumina/core/services/speech_recognition_service.dart';
import 'package:lumina/core/services/voice_recorder_service.dart';
import 'package:lumina/core/widgets/app_snackbar.dart';
import 'package:lumina/core/widgets/voice_messages.dart';
import 'package:lumina/features/chat/domain/chat_bubble.dart';
import 'package:lumina/features/chat/domain/chat_markup.dart';
import 'package:lumina/features/chat/presentation/widgets/chat_design.dart';
import 'package:lumina/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:lumina/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:lumina/features/chat/presentation/widgets/chat_new_chat_dialog.dart';
import 'package:lumina/features/chat/presentation/widgets/chat_typing_indicator.dart';
import 'package:lumina/features/chat/presentation/widgets/chat_voice_picker.dart';
import 'package:lumina/features/chat/presentation/widgets/chat_welcome_view.dart';
import 'package:lumina/l10n/app_localizations.dart';

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

  final List<ChatBubble> _messages = [];
  bool _isLoading = false;

  // Голосовые сообщения (запись → распознавание речи → текст в чат)
  final VoiceRecorderService _voice = VoiceRecorderService();
  // Распознаватель телефона — основной путь, облако — запасной.
  final SpeechRecognitionService _speechInput =
      SpeechRecognitionService.instance;
  bool _usingOnDevice = false;
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
    if (_isRecording) {
      _usingOnDevice ? _speechInput.cancel() : _voice.cancel();
    }
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
            (m) => ChatBubble(
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
      _messages.add(ChatBubble(text: message, isUser: true, isVoice: isVoice));
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
      _messages.add(ChatBubble(text: reply, isUser: false));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  // ─── Голосовые сообщения: запись и распознавание ───────────

  /// Максимум 60 секунд: более длинные записи провайдеры STT
  /// завершают по таймауту, а короткие реплики точнее распознаются.
  static const int _maxVoiceSeconds = 60;

  /// Начинает голосовое сообщение.
  ///
  /// Основной путь — распознаватель телефона (бесплатно, без ключей).
  /// Если его нет (например, на Android без сервиса Google), записываем
  /// аудио и распознаём в облаке.
  Future<void> _startRecording() async {
    if (_isRecording || _isTranscribing || _isStartingRecording) return;
    final loc = AppLocalizations.of(context)!;
    HapticFeedback.mediumImpact();

    _isStartingRecording = true;
    try {
      _usingOnDevice = await _speechInput.isAvailable();
      if (_usingOnDevice) {
        final locale = await _speechInput.localeFor(_languageCode);
        await _speechInput.start(localeId: locale);
        // Распознаватель сам завершает сессию после паузы — тогда
        // отправляем сразу, не дожидаясь нажатия кнопки.
        _speechInput.result.then(
          (_) {
            if (mounted && _isRecording && _usingOnDevice) {
              _finishRecording(send: true);
            }
          },
          onError: (Object _) {
            if (mounted && _isRecording && _usingOnDevice) {
              _finishRecording(send: true);
            }
          },
        );
      } else {
        await _voice.start();
      }
    } on VoiceRecordException catch (e) {
      debugPrint('⚠️ $e');
      if (mounted) _showVoiceError(voiceRecordMessage(loc, e));
      return;
    } catch (e) {
      debugPrint('⚠️ Voice start error: $e');
      if (mounted) _showVoiceError(loc.voiceErrorRecord);
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

    if (_usingOnDevice) {
      await _finishOnDevice(send: send);
      return;
    }
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

  /// Завершает сессию распознавателя телефона и отправляет текст.
  Future<void> _finishOnDevice({required bool send}) async {
    if (!send) {
      await _speechInput.cancel();
      return;
    }
    setState(() => _isTranscribing = true);
    String? text;
    SpeechRecognitionFailure? failure;
    try {
      await _speechInput.stop();
      // Итог приходит после stop(); страховка от «зависшего» сервиса.
      text = await _speechInput.result.timeout(const Duration(seconds: 8));
    } on SpeechRecognitionException catch (e) {
      debugPrint('⚠️ $e');
      failure = e.failure;
    } on TimeoutException {
      final partial = _speechInput.partialText.value.trim();
      if (partial.isNotEmpty) {
        text = partial;
      } else {
        failure = SpeechRecognitionFailure.noSpeech;
      }
    }
    if (!mounted) return;
    setState(() => _isTranscribing = false);

    if (text == null || text.trim().isEmpty) {
      _showVoiceError(
        speechRecognitionMessage(
          AppLocalizations.of(context)!,
          failure ?? SpeechRecognitionFailure.noSpeech,
        ),
      );
      return;
    }
    await _sendMessage(text: text, isVoice: true);
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

  /// Озвучивает сообщение или, если оно уже звучит, останавливает речь.
  Future<void> _toggleSpeech(String text) async {
    final loc = AppLocalizations.of(context)!;
    final plain = plainSpeechText(text);
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

    final pick = await showChatVoicePicker(
      context,
      voices: voices,
      selected: _speech.selectedVoice,
    );
    if (pick != null) _speech.selectVoice(pick.voice);
  }

  Future<void> _startNewChat() async {
    HapticFeedback.lightImpact();
    if (!await confirmNewChat(context)) return;
    await _speech.stop();
    if (!mounted) return;
    setState(() {
      _messages.clear();
      _isLoading = false;
    });
    _aiService.startNewChat();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final hasMessages = _messages.isNotEmpty;

    final inputBar = ChatInputBar(
      controller: _messageController,
      focusNode: _focusNode,
      isLoading: _isLoading,
      isRecording: _isRecording,
      isTranscribing: _isTranscribing,
      recordDuration: _recordDuration,
      usingOnDevice: _usingOnDevice,
      partialText: _speechInput.partialText,
      onSend: _sendMessage,
      onStartRecording: _startRecording,
      onFinishRecording: (send) => _finishRecording(send: send),
      onNewChat: _startNewChat,
    );

    return Scaffold(
      backgroundColor: ChatDesign.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: ChatDesign.textPrimary,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: loc.ttsVoiceSettings,
                    onPressed: _showVoicePicker,
                    icon: const Icon(
                      Icons.record_voice_over_outlined,
                      color: ChatDesign.textSecondary,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: hasMessages
                  ? _ChatMessageList(
                      controller: _scrollController,
                      messages: _messages,
                      isLoading: _isLoading,
                      speakingText: _speech.speakingText,
                      spokenTexts: _spokenTexts,
                      onToggleSpeech: (message) => _toggleSpeech(message.text),
                      inputBar: inputBar,
                    )
                  : ChatWelcomeView(
                      inputArea: inputBar,
                      onSuggestion: (text) => _sendMessage(text: text),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Переписка: список пузырей и «AI печатает…» в конце.
class _ChatMessageList extends StatelessWidget {
  const _ChatMessageList({
    required this.controller,
    required this.messages,
    required this.isLoading,
    required this.speakingText,
    required this.spokenTexts,
    required this.onToggleSpeech,
    required this.inputBar,
  });

  final ScrollController controller;
  final List<ChatBubble> messages;
  final bool isLoading;
  final ValueListenable<String?> speakingText;
  final Set<String> spokenTexts;
  final ValueChanged<ChatBubble> onToggleSpeech;
  final Widget inputBar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: messages.length + (isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == messages.length) return const ChatTypingIndicator();
              final message = messages[index];
              return ChatMessageBubble(
                message: message,
                speakingText: speakingText,
                spokenTexts: spokenTexts,
                onToggleSpeech: onToggleSpeech,
              );
            },
          ),
        ),
        inputBar,
      ],
    );
  }
}
