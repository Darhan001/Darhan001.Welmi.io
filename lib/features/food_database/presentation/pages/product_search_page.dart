import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/food_database/data/open_food_facts_service.dart';
import 'package:lumina/features/food_database/domain/models/food_product.dart';
import 'package:lumina/features/food_database/presentation/pages/barcode_scanner_page.dart';
import 'package:lumina/features/food_database/presentation/widgets/food_portion_sheet.dart';

/// Поиск продукта в открытой базе Open Food Facts.
///
/// Возвращает [FoodDraft] с уже рассчитанной на порцию пищевой ценностью.
class ProductSearchPage extends StatefulWidget {
  const ProductSearchPage({super.key});

  @override
  State<ProductSearchPage> createState() => _ProductSearchPageState();
}

class _ProductSearchPageState extends State<ProductSearchPage> {
  final OpenFoodFactsService _service = OpenFoodFactsService();
  final TextEditingController _queryController = TextEditingController();

  List<FoodProduct> _results = const [];
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _lastQueryWasBarcode = false;
  bool _showClear = false;
  String? _error;

  /// Защита от гонки запросов: применяем ответ только последнего поиска.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _queryController.removeListener(_onQueryChanged);
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final showClear = _queryController.text.isNotEmpty;
    if (showClear != _showClear) {
      setState(() => _showClear = showClear);
    }
  }

  bool _looksLikeBarcode(String query) {
    if (!RegExp(r'^\d+$').hasMatch(query)) return false;
    return query.length == 8 ||
        query.length == 12 ||
        query.length == 13 ||
        query.length == 14;
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty || _isLoading) return;

    FocusScope.of(context).unfocus();
    final requestId = ++_requestId;
    final isBarcode = _looksLikeBarcode(query);

    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = true;
      _lastQueryWasBarcode = isBarcode;
      _results = const [];
    });

    try {
      final List<FoodProduct> products;
      if (isBarcode) {
        final product = await _service.fetchByBarcode(query);
        products = product == null ? const [] : [product];
      } else {
        products = await _service.search(query);
      }

      if (!mounted || requestId != _requestId) return;
      setState(() {
        _results = products;
        _isLoading = false;
      });
    } on OpenFoodFactsException catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = 'Не удалось выполнить поиск. Проверь интернет и повтори.';
        _isLoading = false;
      });
    }
  }

  Future<void> _scanBarcode() async {
    final product = await Navigator.push<FoodProduct>(
      context,
      smoothPageRoute(const BarcodeScannerPage()),
    );
    if (!mounted || product == null) return;
    await _choosePortion(product);
  }

  Future<void> _choosePortion(FoodProduct product) async {
    final draft = await FoodPortionSheet.show(context, product);
    if (!mounted || draft == null) return;
    Navigator.pop(context, draft);
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(tc),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: _buildSearchField(tc),
            ),
            Expanded(child: _buildBody(tc)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tc.card,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: tc.shadow(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back, size: 22, color: tc.text),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'База продуктов',
                  style: GoogleFonts.notoSerif(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: tc.text,
                  ),
                ),
                Text(
                  'Open Food Facts · значения на 100 г',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: tc.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(ThemeColors tc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: tc.shadow(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: tc.inactive),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _queryController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: tc.text,
              ),
              decoration: InputDecoration(
                hintText: 'Название или штрихкод',
                hintStyle: TextStyle(
                  color: tc.textHint,
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_showClear)
            IconButton(
              tooltip: 'Очистить',
              onPressed: () {
                _queryController.clear();
                setState(() {
                  _results = const [];
                  _hasSearched = false;
                  _error = null;
                });
              },
              icon: Icon(Icons.close_rounded, size: 18, color: tc.inactive),
            ),
          IconButton(
            tooltip: 'Сканировать штрихкод',
            onPressed: _isLoading ? null : _scanBarcode,
            icon: Icon(Icons.qr_code_scanner_rounded, color: tc.green),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeColors tc) {
    if (_isLoading) {
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

    if (_error != null) return _buildError(tc);

    if (!_hasSearched) return _buildStart(tc);

    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: tc.card,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 36,
                  color: tc.inactive,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _lastQueryWasBarcode
                    ? 'Продукт не найден'
                    : 'Ничего не найдено',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: tc.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _lastQueryWasBarcode
                    ? 'Этого штрихкода нет в Open Food Facts. '
                          'Проверь цифры или добавь продукт вручную.'
                    : 'Проверь название или отсканируй штрихкод. '
                          'Продукт можно добавить вручную в дневнике.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: tc.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
          child: Text(
            'Найдено: ${_results.length}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: tc.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            physics: const BouncingScrollPhysics(),
            itemCount: _results.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _buildResultCard(_results[index], tc),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(FoodProduct product, ThemeColors tc) {
    final macros = <String>[
      if (product.proteinPer100g != null)
        'Б ${formatNutrient(product.proteinPer100g)}',
      if (product.fatPer100g != null) 'Ж ${formatNutrient(product.fatPer100g)}',
      if (product.carbsPer100g != null)
        'У ${formatNutrient(product.carbsPer100g)}',
    ];

    return GestureDetector(
      onTap: () => _choosePortion(product),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: tc.shadow(0.02),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: tc.text,
                    ),
                  ),
                  if (product.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: tc.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    product.hasNutrition
                        ? macros.isEmpty
                              ? 'Калорийность без БЖУ'
                              : macros.join(' · ')
                        : 'Нет данных о пищевой ценности',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: product.hasNutrition ? tc.green : tc.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatNutrient(product.kcalPer100g),
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: tc.text,
                  ),
                ),
                Text(
                  'ккал / 100 г',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: tc.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: tc.inactive),
          ],
        ),
      ),
    );
  }

  Widget _buildStart(ThemeColors tc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: tc.successBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.travel_explore_rounded,
                size: 42,
                color: tc.green,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Найди продукт по названию',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: tc.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Или отсканируй штрихкод упаковки. '
              'Пищевая ценность пересчитается на твою порцию.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: tc.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Данные добровольные и могут быть неполными — '
              'мы показываем «—», если значения нет в базе.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: tc.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ThemeColors tc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: tc.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: tc.text,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _search,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Повторить'),
              style: OutlinedButton.styleFrom(
                foregroundColor: tc.text,
                side: BorderSide(color: tc.divider),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
