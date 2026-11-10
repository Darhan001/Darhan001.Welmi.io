import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_app_bar.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/food_database/data/open_food_facts_service.dart';
import 'package:lumina/features/food_database/domain/models/food_product.dart';
import 'package:lumina/features/food_database/presentation/open_food_facts_messages.dart';
import 'package:lumina/features/food_database/presentation/pages/barcode_scanner_page.dart';
import 'package:lumina/features/food_database/presentation/widgets/food_portion_sheet.dart';
import 'package:lumina/features/food_database/presentation/widgets/product_result_card.dart';
import 'package:lumina/features/food_database/presentation/widgets/product_search_states.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Поиск продукта в открытой базе Open Food Facts.
///
/// Возвращает [FoodDraft] с уже рассчитанной на порцию пищевой ценностью.
/// Поиск запускается только по кнопке клавиатуры: правила Open Food Facts
/// запрещают поиск «по мере ввода», поэтому debounce не нужен.
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
  bool _isChoosing = false;
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
    if (showClear != _showClear) setState(() => _showClear = showClear);
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty || _isLoading) return;

    FocusScope.of(context).unfocus();
    final loc = AppLocalizations.of(context)!;
    final requestId = ++_requestId;
    final isBarcode = isRetailBarcode(query);

    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = true;
      _lastQueryWasBarcode = isBarcode;
      _results = const [];
    });

    List<FoodProduct> products = const [];
    String? error;
    try {
      if (isBarcode) {
        final product = await _service.fetchByBarcode(query);
        products = product == null ? const [] : [product];
      } else {
        products = await _service.search(query);
      }
    } on OpenFoodFactsException catch (e) {
      error = openFoodFactsMessage(loc, e);
    } catch (e) {
      debugPrint('Product search failed: $e');
      error = loc.foodDbSearchFailed;
    }

    if (!mounted || requestId != _requestId) return;
    setState(() {
      _results = products;
      _error = error;
      _isLoading = false;
    });
  }

  void _clear() {
    _queryController.clear();
    setState(() {
      // Ответ уже отправленного запроса больше не нужен.
      _requestId++;
      _isLoading = false;
      _results = const [];
      _hasSearched = false;
      _error = null;
    });
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
    // Повторное нажатие на карточку не открывает второй лист поверх первого.
    if (_isChoosing) return;
    _isChoosing = true;
    try {
      final draft = await FoodPortionSheet.show(context, product);
      if (!mounted || draft == null) return;
      Navigator.pop(context, draft);
    } finally {
      _isChoosing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: AppAppBar(title: loc.foodDbTitle),
            ),
            Text(
              loc.foodDbSubtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: tc.textSecondary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: _buildSearchField(tc),
            ),
            Expanded(child: _buildBody(tc)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(ThemeColors tc) {
    final loc = AppLocalizations.of(context)!;
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
                hintText: loc.foodDbSearchHint,
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
              tooltip: loc.clearAction,
              onPressed: _clear,
              icon: Icon(Icons.close_rounded, size: 18, color: tc.inactive),
            ),
          IconButton(
            tooltip: loc.foodDbScanBarcode,
            onPressed: _isLoading ? null : _scanBarcode,
            icon: Icon(Icons.qr_code_scanner_rounded, color: tc.green),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeColors tc) {
    if (_isLoading) return const ProductSearchLoading();
    if (_error != null) {
      return ProductSearchError(message: _error!, onRetry: _search);
    }
    if (!_hasSearched) return const ProductSearchStart();
    if (_results.isEmpty) {
      return ProductSearchEmpty(byBarcode: _lastQueryWasBarcode);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
          child: Text(
            AppLocalizations.of(context)!.foodDbFound(_results.length),
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
            itemBuilder: (context, index) {
              final product = _results[index];
              return ProductResultCard(
                product: product,
                onTap: () => _choosePortion(product),
              );
            },
          ),
        ),
      ],
    );
  }
}
