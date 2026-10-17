import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/services/ai_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/l10n/app_localizations.dart';

enum _VoiceStep { idle, listening, processing, result, error }

class VoiceFoodDialog extends StatefulWidget {
  final MealType mealType;
  final Future<void> Function(
    String name,
    int kcal,
    int protein,
    int fat,
    int carbs,
    String info,
  )
  onConfirm;

  const VoiceFoodDialog({
    super.key,
    required this.mealType,
    required this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required MealType mealType,
    required Future<void> Function(
      String name,
      int kcal,
      int protein,
      int fat,
      int carbs,
      String info,
    )
    onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          VoiceFoodDialog(mealType: mealType, onConfirm: onConfirm),
    );
  }

  @override
  State<VoiceFoodDialog> createState() => _VoiceFoodDialogState();
}

class _VoiceFoodDialogState extends State<VoiceFoodDialog>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final AiService _aiService = AiService();

  _VoiceStep _step = _VoiceStep.idle;
  String _recognizedText = '';
  VoiceFoodAnalysisResult? _analysisResult;
  String? _errorMessage;

  // Controllers for editable fields on result step
  late TextEditingController _nameController;
  late TextEditingController _kcalController;
  late TextEditingController _proteinController;
  late TextEditingController _fatController;
  late TextEditingController _carbsController;
  late TextEditingController _clarifyController;

  bool _isEditing = false;
  bool _isSaving = false;

  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;
  String? _recordingPath;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _kcalController = TextEditingController();
    _proteinController = TextEditingController();
    _fatController = TextEditingController();
    _carbsController = TextEditingController();
    _clarifyController = TextEditingController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Автоматически запускаем запись при открытии
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    if (_step == _VoiceStep.listening) {
      _recorder.cancel();
    }
    _recorder.dispose();
    _pulseController.dispose();
    _nameController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    _clarifyController.dispose();
    super.dispose();
  }

  String _mealTitle(BuildContext context) {
    switch (widget.mealType) {
      case MealType.breakfast:
        return AppLocalizations.of(context)!.breakfast;
      case MealType.lunch:
        return AppLocalizations.of(context)!.lunch;
      case MealType.dinner:
        return AppLocalizations.of(context)!.dinner;
      case MealType.snack:
        return AppLocalizations.of(context)!.snack;
    }
  }

  Future<void> _startListening() async {
    final loc = AppLocalizations.of(context)!;
    HapticFeedback.mediumImpact();

    try {
      final allowed = await _recorder.hasPermission();
      if (!mounted) return;
      if (!allowed) {
        setState(() {
          _step = _VoiceStep.error;
          _errorMessage = loc.voiceErrorPermission;
        });
        return;
      }

      if (kIsWeb) {
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.opus,
            bitRate: 64000,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: '',
        );
      } else {
        final path =
            '${Directory.systemTemp.path}/voice_food_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 64000,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: path,
        );
        _recordingPath = path;
      }

      setState(() {
        _step = _VoiceStep.listening;
        _recordDuration = Duration.zero;
        _errorMessage = null;
      });

      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _recordDuration += const Duration(seconds: 1));
        if (_recordDuration.inSeconds >= 45) {
          _stopListeningAndProcess();
        }
      });
    } catch (e) {
      debugPrint('⚠️ Voice record error: $e');
      if (mounted) {
        setState(() {
          _step = _VoiceStep.error;
          _errorMessage = loc.voiceErrorTranscribe;
        });
      }
    }
  }

  Future<void> _stopListeningAndProcess() async {
    if (_step != _VoiceStep.listening) return;
    _recordTimer?.cancel();
    _recordTimer = null;
    HapticFeedback.lightImpact();

    setState(() => _step = _VoiceStep.processing);

    Uint8List? bytes;
    try {
      final stoppedPath = await _recorder.stop();
      if (kIsWeb) {
        if (stoppedPath != null && stoppedPath.isNotEmpty) {
          final uri = Uri.parse(stoppedPath);
          final res = await http.get(uri);
          if (res.statusCode == 200) bytes = res.bodyBytes;
        }
      } else {
        final filePath = stoppedPath ?? _recordingPath;
        if (filePath != null) {
          final file = File(filePath);
          if (await file.exists()) {
            bytes = await file.readAsBytes();
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error stopping recorder: $e');
    }
    _recordingPath = null;

    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        setState(() {
          _step = _VoiceStep.error;
          _errorMessage = AppLocalizations.of(context)!.voiceErrorTranscribe;
        });
      }
      return;
    }

    await _transcribeAndAnalyze(bytes);
  }

  Future<void> _transcribeAndAnalyze(Uint8List bytes) async {
    final loc = AppLocalizations.of(context)!;
    String? text;

    try {
      text = await _aiService.transcribeAudio(
        bytes,
        format: kIsWeb ? 'webm' : 'm4a',
        language: 'ru',
      );
    } catch (e) {
      debugPrint('⚠️ Voice transcription error: $e');
    }

    if (!mounted) return;

    if (text == null || text.trim().isEmpty) {
      setState(() {
        _step = _VoiceStep.error;
        _errorMessage = loc.voiceErrorTranscribe;
      });
      return;
    }

    _recognizedText = text.trim();

    try {
      final result = await _aiService.analyzeFoodText(_recognizedText);
      if (!mounted) return;

      if (result == null || result.items.isEmpty) {
        setState(() {
          _step = _VoiceStep.error;
          _errorMessage = 'Не удалось определить продукты. Попробуй ещё раз.';
        });
        return;
      }

      _populateControllers(result);

      setState(() {
        _analysisResult = result;
        _step = _VoiceStep.result;
        _isEditing = false;
      });
    } catch (e) {
      debugPrint('⚠️ Voice food analysis error: $e');
      if (mounted) {
        setState(() {
          _step = _VoiceStep.error;
          _errorMessage = 'Ошибка анализа продуктов. Попробуй ещё раз.';
        });
      }
    }
  }

  void _populateControllers(VoiceFoodAnalysisResult result) {
    final names = result.items
        .map((i) => '${i.name} (${i.portion})')
        .join(', ');
    _nameController.text = names;
    _kcalController.text = '${result.totalCalories}';
    _proteinController.text = '${result.totalProtein.round()}';
    _fatController.text = '${result.totalFat.round()}';
    _carbsController.text = '${result.totalCarbs.round()}';
    if (result.clarificationNeeded != null) {
      _clarifyController.text = '';
    }
  }

  Future<void> _reanalyzeWithClarification() async {
    final extra = _clarifyController.text.trim();
    if (extra.isEmpty) return;

    setState(() => _step = _VoiceStep.processing);

    final combinedText = '$_recognizedText. Уточнение: $extra';
    _recognizedText = combinedText;

    final result = await _aiService.analyzeFoodText(combinedText);
    if (!mounted) return;

    if (result != null && result.items.isNotEmpty) {
      _populateControllers(result);
      setState(() {
        _analysisResult = result;
        _step = _VoiceStep.result;
      });
    } else {
      setState(() => _step = _VoiceStep.result);
    }
  }

  Future<void> _confirmAndSave() async {
    if (_analysisResult?.clarificationNeeded?.isNotEmpty == true) {
      showWelmiSnackbar(
        context,
        'Уточните количество продукта, чтобы получить примерную оценку.',
        icon: Icons.help_outline_rounded,
      );
      return;
    }
    final name = _nameController.text.trim();
    final kcal = int.tryParse(_kcalController.text.trim()) ?? 0;
    final protein = int.tryParse(_proteinController.text.trim()) ?? 0;
    final fat = int.tryParse(_fatController.text.trim()) ?? 0;
    final carbs = int.tryParse(_carbsController.text.trim()) ?? 0;

    if (name.isEmpty || kcal <= 0) {
      showWelmiSnackbar(
        context,
        AppLocalizations.of(context)!.enterNameAndCalories,
        icon: Icons.info_outline,
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final info =
        _analysisResult?.items
            .map((i) => '${i.name} — ${i.portion}')
            .join('\n') ??
        '';

    await widget.onConfirm(name, kcal, protein, fat, carbs, info);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _formatTimer(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: tc.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * .86,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: tc.inactive.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tc.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.mic_rounded, color: tc.green, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Голосовой ввод: ${_mealTitle(context)}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: tc.text,
                          ),
                        ),
                        Text(
                          'Назови блюдо и количество',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: tc.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: tc.textSecondary,
                      size: 22,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Dynamic state content
              _buildStateBody(tc),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateBody(ThemeColors tc) {
    switch (_step) {
      case _VoiceStep.idle:
      case _VoiceStep.listening:
        return _buildListeningView(tc);
      case _VoiceStep.processing:
        return _buildProcessingView(tc);
      case _VoiceStep.result:
        return _buildResultView(tc);
      case _VoiceStep.error:
        return _buildErrorView(tc);
    }
  }

  // 1) Listening view
  Widget _buildListeningView(ThemeColors tc) {
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
                  onTap: _stopListeningAndProcess,
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
          'Слушаю... (${_formatTimer(_recordDuration)})',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: tc.text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Например: «Два яйца, два куска хлеба и банан»',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: tc.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _stopListeningAndProcess,
          style: ElevatedButton.styleFrom(
            backgroundColor: tc.primary,
            foregroundColor: tc.textOnPrimary,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Text(
            'Готово, распознать',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: tc.textOnPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // 2) Processing view
  Widget _buildProcessingView(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(tc.green),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'AI анализирует продукты...',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: tc.text,
            ),
          ),
          const SizedBox(height: 6),
          if (_recognizedText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '«$_recognizedText»',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: tc.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 3) Result view (карточка подтверждения)
  Widget _buildResultView(ThemeColors tc) {
    final result = _analysisResult!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Распознанный текст
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tc.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tc.divider),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.format_quote_rounded,
                size: 18,
                color: tc.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _recognizedText,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: tc.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Список распознанных продуктов
        Text(
          'Распознано:',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: tc.textSecondary,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tc.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tc.divider),
          ),
          child: Column(
            children: result.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: tc.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${item.name} — ${item.portion}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: tc.text,
                        ),
                      ),
                    ),
                    Text(
                      '~${item.calories} ккал',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: tc.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        // Блок уточнения (если количество не указано точно)
        if (result.clarificationNeeded != null &&
            result.clarificationNeeded!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB347).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFB347).withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.help_outline_rounded,
                      color: Color(0xFFFFB347),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.clarificationNeeded!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: tc.text,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _clarifyController,
                        style: GoogleFonts.inter(fontSize: 13, color: tc.text),
                        decoration: InputDecoration(
                          hintText: 'Например: 150 грамм',
                          hintStyle: TextStyle(
                            color: tc.textHint,
                            fontSize: 13,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: tc.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _reanalyzeWithClarification,
                      icon: Icon(
                        Icons.check_circle_rounded,
                        color: tc.green,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 14),

        // Карточка: Примерная оценка
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Примерная оценка:',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tc.textSecondary,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() => _isEditing = !_isEditing);
              },
              child: Text(
                _isEditing ? 'Скрыть правку' : 'Изменить данные',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: tc.green,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        if (_isEditing) ...[
          // Поля ручной правки
          _buildEditField('Название', _nameController, tc),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildEditField(
                  'Калории',
                  _kcalController,
                  tc,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEditField(
                  'Белки (г)',
                  _proteinController,
                  tc,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildEditField(
                  'Жиры (г)',
                  _fatController,
                  tc,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEditField(
                  'Углеводы (г)',
                  _carbsController,
                  tc,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ] else ...[
          // Компактные макросы
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: tc.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tc.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroCol(
                  'Калории',
                  '${_kcalController.text} ккал',
                  tc.text,
                  tc,
                ),
                _buildMacroCol(
                  'Белки',
                  '${_proteinController.text} г',
                  const Color(0xFF75A47F),
                  tc,
                ),
                _buildMacroCol(
                  'Жиры',
                  '${_fatController.text} г',
                  const Color(0xFFFFB347),
                  tc,
                ),
                _buildMacroCol(
                  'Углеводы',
                  '${_carbsController.text} г',
                  const Color(0xFF4A90E2),
                  tc,
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Кнопки [Сказать заново] и [Добавить в дневник]
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _startListening,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  side: BorderSide(color: tc.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Сказать заново',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tc.text,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed:
                    _isSaving ||
                        _analysisResult?.clarificationNeeded?.isNotEmpty == true
                    ? null
                    : _confirmAndSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tc.primary,
                  foregroundColor: tc.textOnPrimary,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: tc.textOnPrimary,
                        ),
                      )
                    : Text(
                        'Добавить в дневник',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: tc.textOnPrimary,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 4) Error view
  Widget _buildErrorView(ThemeColors tc) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tc.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.error_outline_rounded, color: tc.error, size: 36),
        ),
        const SizedBox(height: 16),
        Text(
          _errorMessage ?? 'Произошла ошибка при распознавании',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: tc.text,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _startListening,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Попробовать снова'),
          style: ElevatedButton.styleFrom(
            backgroundColor: tc.primary,
            foregroundColor: tc.textOnPrimary,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroCol(
    String label,
    String value,
    Color color,
    ThemeColors tc,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: tc.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller,
    ThemeColors tc, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: tc.text,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: tc.textSecondary),
        isDense: true,
        filled: true,
        fillColor: tc.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tc.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tc.divider),
        ),
      ),
    );
  }
}
