import 'package:flutter/material.dart';

import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_button.dart';

/// Пустые состояния и ошибки экрана поиска продуктов.
///
/// Общая раскладка: иконка в круге, заголовок, пояснение.
class _SearchMessage extends StatelessWidget {
  final Widget icon;
  final String title;
  final String body;
  final String? footnote;

  const _SearchMessage({
    required this.icon,
    required this.title,
    required this.body,
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: tc.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: tc.textSecondary,
              ),
            ),
            if (footnote != null) ...[
              const SizedBox(height: 18),
              Text(
                footnote!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: tc.textHint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Стартовый экран до первого поиска.
class ProductSearchStart extends StatelessWidget {
  const ProductSearchStart({super.key});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return _SearchMessage(
      icon: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(color: tc.successBg, shape: BoxShape.circle),
        child: Icon(Icons.travel_explore_rounded, size: 42, color: tc.green),
      ),
      title: 'Найди продукт по названию',
      body:
          'Или отсканируй штрихкод упаковки. '
          'Пищевая ценность пересчитается на твою порцию.',
      footnote:
          'Данные добровольные и могут быть неполными — '
          'мы показываем «—», если значения нет в базе.',
    );
  }
}

/// Поиск выполнен, но ничего не найдено.
class ProductSearchEmpty extends StatelessWidget {
  /// Искали по штрихкоду, а не по названию.
  final bool byBarcode;

  const ProductSearchEmpty({super.key, required this.byBarcode});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return _SearchMessage(
      icon: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(color: tc.card, shape: BoxShape.circle),
        child: Icon(Icons.search_off_rounded, size: 36, color: tc.inactive),
      ),
      title: byBarcode ? 'Продукт не найден' : 'Ничего не найдено',
      body: byBarcode
          ? 'Этого штрихкода нет в Open Food Facts. '
                'Проверь цифры или добавь продукт вручную.'
          : 'Проверь название или отсканируй штрихкод. '
                'Продукт можно добавить вручную в дневнике.',
    );
  }
}

/// Идёт запрос к Open Food Facts.
class ProductSearchLoading extends StatelessWidget {
  const ProductSearchLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: tc.green),
          const SizedBox(height: 16),
          Text(
            'Ищем в Open Food Facts...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tc.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ошибка сети или лимита запросов с кнопкой повтора.
class ProductSearchError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ProductSearchError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: tc.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: tc.text,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              text: 'Повторить',
              icon: Icons.refresh_rounded,
              variant: AppButtonVariant.outline,
              fullWidth: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
