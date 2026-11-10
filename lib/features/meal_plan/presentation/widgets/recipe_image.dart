import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/features/meal_plan/presentation/widgets/recipe_design.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Фото блюда.
///
/// Сначала берётся собственный файл записи (пакет приложения), затем —
/// `strMealThumb` того же блюда из TheMealDB. Если недоступно и то и другое,
/// показывается нейтральный тематический placeholder: фотография другого
/// блюда не подставляется никогда.
class RecipeImage extends StatelessWidget {
  const RecipeImage({
    super.key,
    this.imageUrl,
    this.imagePath,
    required this.label,
  });

  final String? imageUrl;
  final String? imagePath;
  final String label;

  Widget _placeholder(BuildContext context) =>
      _RecipeImagePlaceholder(label: label);

  Widget _networkImage(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) return _placeholder(context);
    return Image.network(
      url,
      fit: BoxFit.cover,
      cacheWidth: 720,
      semanticLabel: label,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const _RecipeImageSkeleton(),
      errorBuilder: (_, __, ___) => _placeholder(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path == null || path.isEmpty) return _networkImage(context);
    return Image.asset(
      path,
      fit: BoxFit.cover,
      cacheWidth: 720,
      semanticLabel: label,
      // Файл не найден — пробуем фото того же блюда по сети.
      errorBuilder: (_, __, ___) => _networkImage(context),
    );
  }
}

class _RecipeImagePlaceholder extends StatelessWidget {
  const _RecipeImagePlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Semantics(
      label: AppLocalizations.of(context)!.recipeNoPhotoLabel(label),
      image: true,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tc.surface,
              RecipeDesign.green.withValues(alpha: tc.isDark ? .16 : .12),
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_rounded,
              color: RecipeDesign.green.withValues(alpha: .75),
              size: 30,
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!.recipePhotoSoon,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: tc.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeImageSkeleton extends StatelessWidget {
  const _RecipeImageSkeleton();

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      color: tc.surface,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: RecipeDesign.green,
        ),
      ),
    );
  }
}
