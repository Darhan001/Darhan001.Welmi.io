import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lumina/core/services/ai_service.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/services/daily_tracker.dart';
import 'package:lumina/features/scanner/presentation/widgets/scanner_controls.dart';
import 'package:lumina/features/scanner/presentation/widgets/scanner_result_view.dart';
import 'package:lumina/features/scanner/presentation/widgets/scanner_start_view.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/core/services/widget_service.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';

class ScannerPage extends StatefulWidget {
  /// Вызывается после успешного добавления блюда в дневник.
  /// Сканер — вкладка MainShell, а не отдельный маршрут, поэтому вместо
  /// Navigator.pop (который выталкивал MainShell и давал чёрный экран)
  /// переключаемся на вкладку «Дневник».
  final VoidCallback? onAddToDiary;

  const ScannerPage({super.key, this.onAddToDiary});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final AiService _ai = AiService();
  final SupabaseService _supabase = SupabaseService();
  final DailyTracker _tracker = DailyTracker();

  XFile? _selectedImageFile;
  bool _isAnalyzing = false;
  bool _isAdding = false; // защита от двойного нажатия «В дневник»
  FoodAnalysisResult? _result;
  String? _error;
  MealType _selectedMealType = MealType.snack;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
      lowerBound: 0.94,
      upperBound: 1.06,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final loc = AppLocalizations.of(context)!;
    try {
      final photo = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (photo == null || !mounted) return;
      setState(() {
        _selectedImageFile = photo;
        _result = null;
        _error = null;
      });
      _analyzeFood();
    } catch (e) {
      // Текст исключения пользователю не показываем — только в лог.
      debugPrint('⚠️ Image picker error: $e');
      if (!mounted) return;
      setState(
        () => _error = source == ImageSource.camera
            ? loc.scannerCameraError
            : loc.scannerGalleryError,
      );
    }
  }

  Future<void> _analyzeFood() async {
    final file = _selectedImageFile;
    if (file == null) return;
    final loc = AppLocalizations.of(context)!;

    setState(() {
      _isAnalyzing = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await _ai.analyzeFoodImage(await file.readAsBytes());
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        if (result != null && result.calories > 0) {
          _result = result;
          hapticSuccess(); // успешное сканирование
        } else {
          _error = loc.scannerNotRecognized;
        }
      });
    } catch (e) {
      debugPrint('⚠️ Food scan error: $e');
      if (!mounted) return;
      setState(() {
        _error = loc.scannerAiError;
        _isAnalyzing = false;
      });
    }
  }

  /// «Заново»: возвращает стартовый экран. Раньше сбрасывалось только фото,
  /// и под стартовым экраном оставались кнопки прошлого результата.
  void _restart() => setState(() {
    _selectedImageFile = null;
    _result = null;
    _error = null;
  });

  Future<void> _addToDiary() async {
    final result = _result;
    if (result == null || _isAdding) return;
    final loc = AppLocalizations.of(context)!;
    final userId = AuthService().userId;
    if (userId == null) {
      showWelmiSnackbar(context, loc.signInRequired, icon: Icons.login);
      return;
    }

    _isAdding = true;
    try {
      await _supabase.addFoodEntryWithItem(
        FoodEntry(
          userId: userId,
          mealType: _selectedMealType,
          date: DateTime.now(),
          totalCalories: result.calories,
        ),
        (entryId) => MealItem(
          foodEntryId: entryId,
          name: result.name,
          calories: result.calories,
          proteinGrams: result.proteinGrams,
          fatGrams: result.fatGrams,
          carbsGrams: result.carbsGrams,
          amountGrams: result.amountGrams,
        ),
      );

      await _tracker.loadToday();
      if (!mounted) return;
      hapticSuccess();
      WidgetService().updateAll();
      showWelmiSnackbar(
        context,
        loc.scannerAdded(result.calories),
        icon: Icons.check_circle,
      );
      _restart();
      // Сканер — вкладка MainShell, а не отдельный маршрут:
      // Navigator.pop выталкивал MainShell -> чёрный экран.
      if (widget.onAddToDiary != null) {
        widget.onAddToDiary!();
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('⚠️ Scanner save error: $e');
      if (mounted) {
        showWelmiSnackbar(context, loc.saveError, icon: Icons.error_outline);
      }
    } finally {
      _isAdding = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _selectedImageFile != null;
    return Scaffold(
      backgroundColor: ScannerColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: ScannerColors.gradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const ScannerHeader(),
              Expanded(
                child: hasPhoto
                    ? ScannerResultView(
                        photo: _selectedImageFile!,
                        isAnalyzing: _isAnalyzing,
                        error: _error,
                        result: _result,
                        mealType: _selectedMealType,
                        onPick: _pick,
                        onRetry: _analyzeFood,
                        onMealTypeChanged: (type) =>
                            setState(() => _selectedMealType = type),
                      )
                    : ScannerStartView(pulse: _pulseController),
              ),
              if (!hasPhoto)
                ScannerSourceButtons(
                  onCamera: () => _pick(ImageSource.camera),
                  onGallery: () => _pick(ImageSource.gallery),
                ),
              if (_result != null && !_isAnalyzing)
                ScannerActionButtons(
                  onRestart: _restart,
                  onAddToDiary: _addToDiary,
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
