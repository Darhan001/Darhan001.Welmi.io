import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/services/ai_service.dart';
import 'package:lumina/core/theme/app_colors.dart';
import 'package:lumina/features/scanner/presentation/widgets/scanner_controls.dart';
import 'package:lumina/features/scanner/presentation/widgets/scanner_nutrition_card.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Фото блюда и состояние распознавания: загрузка, ошибка или результат.
class ScannerResultView extends StatelessWidget {
  const ScannerResultView({
    super.key,
    required this.photo,
    required this.isAnalyzing,
    required this.error,
    required this.result,
    required this.mealType,
    required this.onPick,
    required this.onRetry,
    required this.onMealTypeChanged,
  });

  final XFile photo;
  final bool isAnalyzing;
  final String? error;
  final FoodAnalysisResult? result;
  final MealType mealType;
  final ValueChanged<ImageSource> onPick;
  final VoidCallback onRetry;
  final ValueChanged<MealType> onMealTypeChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final image = kIsWeb
        ? Image.network(
            photo.path,
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
          )
        : Image.file(
            File(photo.path),
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
          );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Stack(
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(24), child: image),
              if (!isAnalyzing) ...[
                Positioned(
                  top: 12,
                  left: 12,
                  child: _CircleButton(
                    icon: Icons.photo_library,
                    tooltip: loc.gallery,
                    onTap: () => onPick(ImageSource.gallery),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _CircleButton(
                    icon: Icons.camera_alt,
                    tooltip: loc.camera,
                    onTap: () => onPick(ImageSource.camera),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (isAnalyzing) ...[
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppColors.brand),
            const SizedBox(height: 16),
            Text(
              loc.scannerAnalyzing,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (error != null)
            ScannerErrorView(message: error!, onRetry: onRetry)
          else if (result != null) ...[
            ScannerMealTypeSelector(
              selected: mealType,
              onChanged: onMealTypeChanged,
            ),
            const SizedBox(height: 16),
            ScannerNutritionCard(result: result!),
          ],
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        foregroundColor: Colors.white,
      ),
    );
  }
}

/// Действия после распознавания: «Заново» и «В дневник».
class ScannerActionButtons extends StatelessWidget {
  const ScannerActionButtons({
    super.key,
    required this.onRestart,
    required this.onAddToDiary,
  });

  final VoidCallback onRestart;
  final VoidCallback onAddToDiary;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRestart,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: shape,
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(loc.scannerRetake),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onAddToDiary,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: shape,
              ),
              icon: const Icon(Icons.bookmark_add_rounded, size: 18),
              label: Text(loc.scannerToDiary),
            ),
          ),
        ],
      ),
    );
  }
}
