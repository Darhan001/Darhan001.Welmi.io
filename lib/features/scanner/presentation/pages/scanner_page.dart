import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lumina/core/services/ai_service.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/services/daily_tracker.dart';
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

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          _selectedImageFile = photo;
          _result = null;
          _error = null;
        });
        _analyzeFood();
      }
    } catch (e) {
      setState(() => _error = 'Ошибка камеры: ${e.toString()}');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImageFile = image;
          _result = null;
          _error = null;
        });
        _analyzeFood();
      }
    } catch (e) {
      setState(() => _error = 'Ошибка галереи: ${e.toString()}');
    }
  }

  Future<void> _analyzeFood() async {
    if (_selectedImageFile == null) return;

    setState(() {
      _isAnalyzing = true;
      _error = null;
      _result = null;
    });

    try {
      final bytes = await _selectedImageFile!.readAsBytes();
      final result = await _ai.analyzeFoodImage(bytes);

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          if (result != null && result.calories > 0) {
            _result = result;
            hapticSuccess(); // успешное сканирование
          } else {
            _error = "Welmi AI не удалось распознать еду. Попробуй другое фото.";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка связи с AI. Проверь интернет.';
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _addToDiary() async {
    if (_result == null || _isAdding) return;
    _isAdding = true;
    final userId = AuthService().userId;
    if (userId == null) {
      _isAdding = false;
      showWelmiSnackbar(context, 'Войди в аккаунт', icon: Icons.login);
      return;
    }

    try {
      final entry = await _supabase.addFoodEntry(FoodEntry(
        userId: userId,
        mealType: _selectedMealType,
        date: DateTime.now(),
        totalCalories: _result!.calories,
      ));

      await _supabase.addMealItem(MealItem(
        foodEntryId: entry.id,
        name: _result!.name,
        calories: _result!.calories,
        proteinGrams: _result!.proteinGrams,
        fatGrams: _result!.fatGrams,
        carbsGrams: _result!.carbsGrams,
        amountGrams: _result!.amountGrams,
      ));

      await _tracker.loadToday();
      if (mounted) {
        hapticSuccess();
        WidgetService().updateAll();
        showWelmiSnackbar(context,
            'Добавлено: ${_result!.calories} ккал',
            icon: Icons.check_circle);
        // Сканер — вкладка MainShell, а не отдельный маршрут:
        // Navigator.pop выталкивал MainShell -> чёрный экран.
        if (widget.onAddToDiary != null) {
          widget.onAddToDiary!();
        } else {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        showWelmiSnackbar(context, 'Ошибка сохранения',
            icon: Icons.error_outline);
      }
    }
    _isAdding = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1210),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B100E), Color(0xFF14211A), Color(0xFF0C1210)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _selectedImageFile != null
                    ? _buildResultView()
                    : _buildStartView(),
              ),
              if (_selectedImageFile == null) _buildSourceButtons(),
              if (_result != null && !_isAnalyzing) _buildActionButtons(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Шапка ───
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF75A47F), Color(0xFF4A8C5C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF75A47F).withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.document_scanner_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [               Text(AppLocalizations.of(context)!.aiChatTitle,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900)),
              Text('Фото блюда → калории и БЖУ',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Стартовый экран ───
  Widget _buildStartView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _pulseController,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF75A47F).withValues(alpha: 0.35),
                    const Color(0xFF75A47F).withValues(alpha: 0.0),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(28),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 40),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('Сфотографируй еду',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Welmi AI определит калории, белки, жиры и углеводы',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                  height: 1.4),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [               _buildFeatureChip(Icons.local_fire_department, AppLocalizations.of(context)!.kcalLabel),
              const SizedBox(width: 8),               _buildFeatureChip(Icons.spa_outlined, AppLocalizations.of(context)!.protein),
              const SizedBox(width: 8),               _buildFeatureChip(Icons.water_drop_outlined, AppLocalizations.of(context)!.fat),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF8BC98E)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ─── Кнопки источника фото ───
  Widget _buildSourceButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildSourceButton(
                Icons.camera_alt_rounded, 'Камера', true, _takePhoto),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSourceButton(
                Icons.photo_library_outlined, 'Галерея', false, _pickFromGallery),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceButton(
      IconData icon, String label, bool primary, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: primary
              ? const LinearGradient(
                  colors: [Color(0xFF75A47F), Color(0xFF4A8C5C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: primary ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: primary
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: const Color(0xFF4A8C5C).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ─── Экран результата ───
  Widget _buildResultView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: kIsWeb
                    ? Image.network(_selectedImageFile!.path,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover)
                    : Image.file(File(_selectedImageFile!.path),
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover),
              ),
              if (!_isAnalyzing) ...[
                Positioned(
                    top: 12,
                    right: 12,
                    child: _buildSmallCircleBtn(Icons.camera_alt, _takePhoto)),
                Positioned(
                    top: 12,
                    left: 12,
                    child: _buildSmallCircleBtn(
                        Icons.photo_library, _pickFromGallery)),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (_isAnalyzing) _buildAnalyzingIndicator(),
          if (_error != null && !_isAnalyzing) _buildErrorView(),
          if (_result != null && !_isAnalyzing) ...[
            _buildMealTypeSelector(),
            const SizedBox(height: 16),
            _buildNutritionResult(),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalyzingIndicator() {
    return Column(
      children: [
        const SizedBox(height: 24),
        const CircularProgressIndicator(color: Color(0xFF75A47F)),
        const SizedBox(height: 16),
        Text('Анализируем фото...',
            style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSmallCircleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _analyzeFood,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            child: const Text('Повторить',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTypeSelector() {
    final types = [
      (MealType.breakfast, 'Завтрак'),
      (MealType.lunch, 'Обед'),
      (MealType.dinner, 'Ужин'),
      (MealType.snack, 'Перекус'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: types.map((t) {
          final isSel = _selectedMealType == t.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedMealType = t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSel ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(t.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: isSel
                            ? Colors.black
                            : Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNutritionResult() {
    final r = _result!;
    final maxMacro = [
      r.proteinGrams,
      r.fatGrams,
      r.carbsGrams,
    ].fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF2F8F0)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3E5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.restaurant_rounded,
                    color: Color(0xFF75A47F), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name,
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87)),
                    if (r.description.isNotEmpty)
                      Text(r.description,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black45),
                          maxLines: 2),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${r.calories}',
                  style: GoogleFonts.inter(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87)),
              const SizedBox(width: 6),
              Text('ккал',
                  style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black38,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 22),           _buildMacroBar(AppLocalizations.of(context)!.protein, r.proteinGrams, maxMacro,
              const Color(0xFF75A47F)),
          const SizedBox(height: 12),           _buildMacroBar(AppLocalizations.of(context)!.fat, r.fatGrams, maxMacro, const Color(0xFFFFB347)),
          const SizedBox(height: 12),
          _buildMacroBar(               AppLocalizations.of(context)!.carbs, r.carbsGrams, maxMacro, const Color(0xFF4A90E2)),
        ],
      ),
    );
  }

  Widget _buildMacroBar(String label, double value, double max, Color color) {
    final fraction = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 76,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 10,
              color: const Color(0xFFE6EEE3),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction,
                child: Container(color: color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 52,
          child: Text('${value.toStringAsFixed(1)}г',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87)),
        ),
      ],
    );
  }

  // ─── Действия после распознавания ───
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _selectedImageFile = null),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.25)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Заново',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _addToDiary,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A8C5C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.bookmark_add_rounded, size: 18),
              label: const Text('В дневник',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
