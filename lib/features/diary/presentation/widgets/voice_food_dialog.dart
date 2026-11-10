import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/services/ai_service.dart';
import 'package:lumina/core/services/speech_recognition_service.dart';
import 'package:lumina/core/services/voice_recorder_service.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/core/widgets/voice_messages.dart';
import 'package:lumina/features/diary/presentation/widgets/voice_food_error_view.dart';
import 'package:lumina/features/diary/presentation/widgets/voice_food_listening_view.dart';
import 'package:lumina/features/diary/presentation/widgets/voice_food_processing_view.dart';
import 'package:lumina/features/diary/presentation/widgets/voice_food_result_view.dart';
import 'package:lumina/features/diary/presentation/widgets/voice_food_sheet.dart';
import 'package:lumina/core/widgets/meal_type_label.dart';
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

class _VoiceFoodDialogState extends State<VoiceFoodDialog> {
  static const int _maxVoiceSeconds = 45;

  final VoiceRecorderService _recorder = VoiceRecorderService();
  final SpeechRecognitionService _speechInput =
      SpeechRecognitionService.instance;
  bool _usingOnDevice = false;
  final AiService _aiService = AiService();

  _VoiceStep _step = _VoiceStep.idle;
  String _recognizedText = '';
  VoiceFoodAnalysisResult? _analysisResult;
  String? _errorMessage;

  // Controllers for editable fields on result step
  late final TextEditingController _nameController;
  late final TextEditingController _kcalController;
  late final TextEditingController _proteinController;
  late final TextEditingController _fatController;
  late final TextEditingController _carbsController;
  late final TextEditingController _clarifyController;

  bool _isEditing = false;
  bool _isSaving = false;

  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _kcalController = TextEditingController();
    _proteinController = TextEditingController();
    _fatController = TextEditingController();
    _carbsController = TextEditingController();
    _clarifyController = TextEditingController();

    // Автоматически запускаем запись при открытии
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    if (_step == _VoiceStep.listening) {
      _usingOnDevice ? _speechInput.cancel() : _recorder.cancel();
    }
    _recorder.dispose();
    _nameController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    _clarifyController.dispose();
    super.dispose();
  }

  String _mealTitle(BuildContext context) =>
      AppLocalizations.of(context)!.mealTypeLabel(widget.mealType);

  Future<void> _startListening() async {
    final loc = AppLocalizations.of(context)!;
    HapticFeedback.mediumImpact();

    // Основной путь — распознаватель телефона (без ключей и баланса),
    // запасной — запись и облачное распознавание.
    try {
      _usingOnDevice = await _speechInput.isAvailable();
      if (_usingOnDevice) {
        await _speechInput.start(localeId: await _speechInput.localeFor('ru'));
        // Сессия может закончиться сама после паузы в речи.
        _speechInput.result.then(
          (_) => _autoFinishOnDevice(),
          onError: (Object _) => _autoFinishOnDevice(),
        );
      } else {
        await _recorder.start();
      }
    } on VoiceRecordException catch (e) {
      debugPrint('⚠️ $e');
      if (!mounted) return;
      setState(() {
        _step = _VoiceStep.error;
        _errorMessage = voiceRecordMessage(loc, e);
      });
      return;
    } catch (e) {
      debugPrint('⚠️ Voice start error: $e');
      if (!mounted) return;
      setState(() {
        _step = _VoiceStep.error;
        _errorMessage = loc.voiceErrorRecord;
      });
      return;
    }
    if (!mounted) return;

    setState(() {
      _step = _VoiceStep.listening;
      _recordDuration = Duration.zero;
      _errorMessage = null;
    });

    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _recordDuration += const Duration(seconds: 1));
      if (_recordDuration.inSeconds >= _maxVoiceSeconds) {
        _stopListeningAndProcess();
      }
    });
  }

  Future<void> _stopListeningAndProcess() async {
    if (_step != _VoiceStep.listening) return;
    _recordTimer?.cancel();
    _recordTimer = null;
    HapticFeedback.lightImpact();

    setState(() => _step = _VoiceStep.processing);

    if (_usingOnDevice) {
      await _finishOnDevice();
      return;
    }

    Uint8List bytes;
    try {
      bytes = await _recorder.stopAndRead();
    } on VoiceRecordException catch (e) {
      debugPrint('⚠️ $e');
      if (mounted) {
        setState(() {
          _step = _VoiceStep.error;
          _errorMessage = voiceRecordMessage(AppLocalizations.of(context)!, e);
        });
      }
      return;
    }

    await _transcribeAndAnalyze(bytes);
  }

  void _autoFinishOnDevice() {
    if (mounted && _usingOnDevice && _step == _VoiceStep.listening) {
      _stopListeningAndProcess();
    }
  }

  Future<void> _finishOnDevice() async {
    final loc = AppLocalizations.of(context)!;
    String? text;
    SpeechRecognitionFailure? failure;
    try {
      await _speechInput.stop();
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
    if (text == null || text.trim().isEmpty) {
      setState(() {
        _step = _VoiceStep.error;
        _errorMessage = speechRecognitionMessage(
          loc,
          failure ?? SpeechRecognitionFailure.noSpeech,
        );
      });
      return;
    }
    await _analyzeText(text);
  }

  Future<void> _transcribeAndAnalyze(Uint8List bytes) async {
    final loc = AppLocalizations.of(context)!;
    String text;

    try {
      text = await _aiService.transcribeAudio(
        bytes,
        format: _recorder.format,
        language: 'ru',
      );
    } on VoiceTranscriptionException catch (e) {
      debugPrint('⚠️ Voice transcription error: $e');
      if (!mounted) return;
      setState(() {
        _step = _VoiceStep.error;
        _errorMessage = voiceTranscriptionMessage(loc, e.failure);
      });
      return;
    }

    if (!mounted) return;
    await _analyzeText(text);
  }

  /// Определяет продукты и КБЖУ по распознанному тексту.
  Future<void> _analyzeText(String text) async {
    final loc = AppLocalizations.of(context)!;
    _recognizedText = text.trim();
    setState(() => _step = _VoiceStep.processing);

    try {
      final result = await _aiService.analyzeFoodText(_recognizedText);
      if (!mounted) return;

      if (result == null || result.items.isEmpty) {
        setState(() {
          _step = _VoiceStep.error;
          _errorMessage = loc.voiceFoodNotRecognized;
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
          _errorMessage = loc.voiceFoodAnalysisError;
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

  @override
  Widget build(BuildContext context) {
    return VoiceFoodSheet(
      mealTitle: _mealTitle(context),
      child: _buildStateBody(),
    );
  }

  Widget _buildStateBody() {
    switch (_step) {
      case _VoiceStep.idle:
      case _VoiceStep.listening:
        return VoiceFoodListeningView(
          duration: _recordDuration,
          usingOnDevice: _usingOnDevice,
          partialText: _speechInput.partialText,
          onStop: _stopListeningAndProcess,
        );
      case _VoiceStep.processing:
        return VoiceFoodProcessingView(recognizedText: _recognizedText);
      case _VoiceStep.result:
        return VoiceFoodResultView(
          result: _analysisResult!,
          recognizedText: _recognizedText,
          isEditing: _isEditing,
          isSaving: _isSaving,
          nameController: _nameController,
          kcalController: _kcalController,
          proteinController: _proteinController,
          fatController: _fatController,
          carbsController: _carbsController,
          clarifyController: _clarifyController,
          onToggleEditing: () => setState(() => _isEditing = !_isEditing),
          onSubmitClarification: _reanalyzeWithClarification,
          onRestart: _startListening,
          onSave: _confirmAndSave,
        );
      case _VoiceStep.error:
        return VoiceFoodErrorView(
          message: _errorMessage,
          onRetry: _startListening,
        );
    }
  }
}
