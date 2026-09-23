import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/services/user_data_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/models/supabase_models.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final UserDataService _userData = UserDataService();
  bool _isLoading = true;
  String _selectedChip = 'Все';
  String? _errorMessage;

  final List<String> _chips = ['Все', 'Замеры', '% жира'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await _userData.loadAll();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (_userData.error != null && _userData.profile == null) {
          _errorMessage = 'Не удалось загрузить данные. Проверьте подключение.';
        }
      });
    }
  }

  // ─── Weight helpers ───

  List<double> get _weightHistory =>
      _userData.weightEntries.reversed.map((e) => e.weightKg).toList();

  double? get _currentWeight => _userData.latestWeight;
  double? get _startWeight =>
      _userData.weightEntries.isNotEmpty ? _userData.weightEntries.last.weightKg : null;
  double? get _weightLoss =>
      _startWeight != null && _currentWeight != null
          ? _startWeight! - _currentWeight!
          : null;

  // ─── Быстрые действия (вместо нерабочей иконки) ───

  void _showQuickActions(ThemeColors tc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: tc.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Быстрые действия',
                  style: GoogleFonts.notoSerif(
                      fontSize: 20, fontWeight: FontWeight.w900, color: tc.text)),
              const SizedBox(height: 16),
              _buildActionTile(tc, Icons.monitor_weight_outlined, 'Записать вес',
                  const Color(0xFF75A47F), () {
                Navigator.pop(ctx);
                Future<void>.delayed(const Duration(milliseconds: 120), () {
                  if (mounted) _showRecordWeightDialog();
                });
              }),
              _buildActionTile(tc, Icons.straighten, 'Записать замеры',
                  const Color(0xFF4A90E2), () {
                Navigator.pop(ctx);
                Future<void>.delayed(const Duration(milliseconds: 120), () {
                  if (mounted) _showRecordMeasurementsDialog();
                });
              }),
              _buildActionTile(tc, Icons.monitor_heart_outlined, 'Записать % жира',
                  const Color(0xFFAB47BC), () {
                Navigator.pop(ctx);
                Future<void>.delayed(const Duration(milliseconds: 120), () {
                  if (mounted) _showRecordBodyFatDialog();
                });
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(ThemeColors tc, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tc.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: tc.text)),
            const Spacer(),
            Icon(Icons.chevron_right, size: 18, color: tc.textHint),
          ],
        ),
      ),
    );
  }

  // ─── Dialogs ───

  void _showRecordWeightDialog() {
    final current = _currentWeight ?? 70.0;
    double newWeight = current;
    final controller = TextEditingController(text: current.toStringAsFixed(1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final tc = ThemeColors.of(context);
        return Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Записать вес',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tc.text)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  SizedBox(
                    width: 120,
                    child: TextField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: tc.surface,
                      ),
                      controller: controller,
                      onChanged: (v) => newWeight = double.tryParse(v) ?? current,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 32, fontWeight: FontWeight.w900, color: tc.text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('кг',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: tc.textSecondary)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _userData.saveWeight(newWeight);
                    if (context.mounted) Navigator.pop(context);
                    if (mounted) setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tc.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Сохранить',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRecordMeasurementsDialog() {
    final latest = _userData.measurements.isNotEmpty
        ? _userData.measurements.first
        : null;

    double chest = latest?.chestCm ?? 0;
    double waist = latest?.waistCm ?? 0;
    double hips = latest?.hipsCm ?? 0;
    double arm = latest?.leftArmCm ?? 0;
    double thigh = latest?.leftThighCm ?? 0;
    double neck = latest?.neckCm ?? 0;

    final chestC = TextEditingController(text: chest > 0 ? chest.toStringAsFixed(0) : '');
    final waistC = TextEditingController(text: waist > 0 ? waist.toStringAsFixed(0) : '');
    final hipsC = TextEditingController(text: hips > 0 ? hips.toStringAsFixed(0) : '');
    final armC = TextEditingController(text: arm > 0 ? arm.toStringAsFixed(0) : '');
    final thighC = TextEditingController(text: thigh > 0 ? thigh.toStringAsFixed(0) : '');
    final neckC = TextEditingController(text: neck > 0 ? neck.toStringAsFixed(0) : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final tc = ThemeColors.of(ctx);
        return Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Записать замеры',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tc.text)),
                const SizedBox(height: 20),
                _buildMeasureField(tc, 'Грудь (см)', chestC, (v) => chest = double.tryParse(v) ?? 0),
                const SizedBox(height: 12),
                _buildMeasureField(tc, 'Талия (см)', waistC, (v) => waist = double.tryParse(v) ?? 0),
                const SizedBox(height: 12),
                _buildMeasureField(tc, 'Бёдра (см)', hipsC, (v) => hips = double.tryParse(v) ?? 0),
                const SizedBox(height: 12),
                _buildMeasureField(tc, 'Рука (см)', armC, (v) => arm = double.tryParse(v) ?? 0),
                const SizedBox(height: 12),
                _buildMeasureField(tc, 'Бедро (см)', thighC, (v) => thigh = double.tryParse(v) ?? 0),
                const SizedBox(height: 12),
                _buildMeasureField(tc, 'Шея (см)', neckC, (v) => neck = double.tryParse(v) ?? 0),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final userId = _userData.profile?.id ?? '';
                      if (userId.isEmpty) return;
                      final measurement = BodyMeasurement(
                        userId: userId,
                        date: DateTime.now(),
                        chestCm: chest > 0 ? chest : null,
                        waistCm: waist > 0 ? waist : null,
                        hipsCm: hips > 0 ? hips : null,
                        leftArmCm: arm > 0 ? arm : null,
                        rightArmCm: arm > 0 ? arm : null,
                        leftThighCm: thigh > 0 ? thigh : null,
                        rightThighCm: thigh > 0 ? thigh : null,
                        neckCm: neck > 0 ? neck : null,
                      );
                      await _userData.saveMeasurement(measurement);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tc.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Сохранить замеры',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMeasureField(ThemeColors tc, String label, TextEditingController c, ValueChanged<String> onChanged) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: tc.text))),
        const Spacer(),
        SizedBox(
          width: 80,
          child: TextField(
            controller: c,
            keyboardType: TextInputType.number,
            onChanged: onChanged,
            textAlign: TextAlign.center,
            style: TextStyle(color: tc.text),
            decoration: InputDecoration(
              hintText: 'см',
              hintStyle: TextStyle(color: tc.textHint),
              filled: true,
              fillColor: tc.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tc.divider),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  void _showRecordBodyFatDialog() {
    double percent = _userData.bodyFatEntries.isNotEmpty
        ? _userData.bodyFatEntries.first.bodyFatPercent
        : 20;
    final controller = TextEditingController(text: percent.toStringAsFixed(1));
    String method = _userData.bodyFatEntries.isNotEmpty
        ? (_userData.bodyFatEntries.first.method ?? 'manual')
        : 'manual';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final tc = ThemeColors.of(context);
        return Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Записать % жира',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tc.text)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      SizedBox(
                        width: 120,
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: tc.surface,
                          ),
                          controller: controller,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              fontSize: 32, fontWeight: FontWeight.w900, color: tc.text),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('%',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold, color: tc.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMethodChip(tc, 'Калипер', Icons.monitor_weight_outlined, 'caliper', method, (m) {
                        setSheetState(() => method = m);
                      }),
                      const SizedBox(width: 8),
                      _buildMethodChip(tc, 'Весы', Icons.monitor_heart_outlined, 'scale', method, (m) {
                        setSheetState(() => method = m);
                      }),
                      const SizedBox(width: 8),
                      _buildMethodChip(tc, 'Вручную', Icons.edit, 'manual', method, (m) {
                        setSheetState(() => method = m);
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final pct = double.tryParse(controller.text) ?? percent;
                        await _userData.saveBodyFat(pct, method: method);
                        if (context.mounted) Navigator.pop(context);
                        if (mounted) setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tc.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Сохранить',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMethodChip(ThemeColors tc, String label, IconData icon, String value, String selected, ValueChanged<String> onTap) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? tc.primary : tc.surface,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? null : Border.all(color: tc.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : tc.textSecondary),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : tc.textSecondary)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return ListenableBuilder(
      listenable: _userData,
      builder: (context, _) {
        if (_isLoading) {
          return Scaffold(
            backgroundColor: tc.background,
            body: Center(child: CircularProgressIndicator(color: tc.primary)),
          );
        }

        if (_errorMessage != null) {
          return Scaffold(
            backgroundColor: tc.background,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off_rounded, size: 64, color: tc.textHint),
                      const SizedBox(height: 24),
                      Text(_errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: tc.text, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tc.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Повторить', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: tc.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Header: рабочая кнопка быстрых действий + заголовок + обновление
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => _showQuickActions(tc),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: tc.card,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.add_chart_rounded, size: 22, color: tc.text),
                        ),
                      ),
                      Text('Прогресс',
                          style: GoogleFonts.notoSerif(
                              fontWeight: FontWeight.w900, fontSize: 18, color: tc.text)),
                      GestureDetector(
                        onTap: () => _loadData(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: tc.card,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.refresh_rounded, size: 22, color: tc.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Chips — показываем, если есть хоть какие-то данные
                  if (_userData.profile != null ||
                      _userData.weightEntries.isNotEmpty ||
                      _userData.measurements.isNotEmpty ||
                      _userData.bodyFatEntries.isNotEmpty)
                    Row(
                      children: _chips.map((chip) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _buildChip(chip, _selectedChip == chip),
                      )).toList(),
                    ),
                  const SizedBox(height: 30),
                  // Empty state if no data at all
                  if (_userData.profile == null &&
                      _userData.weightEntries.isEmpty &&
                      _userData.measurements.isEmpty &&
                      _userData.bodyFatEntries.isEmpty)
                    _buildEmptyState(tc)
                  else ...[
                    if (_selectedChip == 'Все') _buildAllTab(tc),
                    if (_selectedChip == 'Замеры') _buildMeasurementsTab(tc),
                    if (_selectedChip == '% жира') _buildBodyFatTab(tc),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeColors tc) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.bar_chart_rounded, size: 64, color: tc.textHint),
          const SizedBox(height: 24),
          Text('Нет данных для отображения',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: tc.text)),
          const SizedBox(height: 12),
          Text('Начните записывать вес, замеры и процент жира,\nчтобы увидеть свой прогресс',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: tc.textSecondary, height: 1.4)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showRecordWeightDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Записать первый вес', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: tc.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB: ВСЕ ───

  Widget _buildAllTab(ThemeColors tc) {
    return Column(
      children: [
        if (_currentWeight != null) _buildWeightCard(tc),
        if (_currentWeight != null) const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _showRecordWeightDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: tc.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
          child: const Text('+ Записать вес',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 32),
        // Activity heatmap
        Text('Активность записей',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: tc.text)),
        const SizedBox(height: 16),
        _buildActivityHeatmap(tc),
      ],
    );
  }

  Widget _buildWeightCard(ThemeColors tc) {
    final loss = _weightLoss ?? 0;
    final weights = _weightHistory;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: tc.shadow(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ТЕКУЩИЙ ВЕС',
                      style: TextStyle(fontSize: 10, color: tc.textHint, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _currentWeight!.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                            fontSize: 32, fontWeight: FontWeight.w900, color: tc.text),
                      ),
                      const SizedBox(width: 4),
                      Text('кг',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tc.textSecondary)),
                    ],
                  ),
                ],
              ),
              if (loss > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF75A47F).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_downward, size: 12, color: Color(0xFF75A47F)),
                      Text(' ${loss.toStringAsFixed(1)} кг',
                          style: const TextStyle(
                              color: Color(0xFF75A47F), fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
          if (weights.length >= 2) ...[
            const SizedBox(height: 30),
            SizedBox(
              height: 150,
              width: double.infinity,
              child: CustomPaint(
                painter: ProgressChartPainter(weightHistory: weights, color: tc.primary),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${DateTime.now().subtract(Duration(days: weights.length - 1)).day} ${_getMonthName(DateTime.now().subtract(Duration(days: weights.length - 1)))}',
                  style: TextStyle(fontSize: 10, color: tc.textHint)),
                Text(
                  '${DateTime.now().day} ${_getMonthName(DateTime.now())}',
                  style: TextStyle(fontSize: 10, color: tc.textHint)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── TAB: ЗАМЕРЫ ───

  Widget _buildMeasurementsTab(ThemeColors tc) {
    final measurements = _userData.measurements;

    return Column(
      children: [
        if (measurements.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: tc.card,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: tc.shadow(0.04), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Последние замеры',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: tc.text)),
                    Text(
                      '${measurements.first.date.day}.${measurements.first.date.month}',
                      style: TextStyle(fontSize: 12, color: tc.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (measurements.first.chestCm != null)
                  _buildMeasureRow('Грудь', measurements.first.chestCm!, null, tc),
                if (measurements.first.waistCm != null)
                  _buildMeasureRow('Талия', measurements.first.waistCm!, null, tc),
                if (measurements.first.hipsCm != null)
                  _buildMeasureRow('Бёдра', measurements.first.hipsCm!, null, tc),
                if (measurements.first.leftArmCm != null)
                  _buildMeasureRow('Рука', measurements.first.leftArmCm!, null, tc),
                if (measurements.first.leftThighCm != null)
                  _buildMeasureRow('Бедро', measurements.first.leftThighCm!, null, tc),
                if (measurements.first.neckCm != null)
                  _buildMeasureRow('Шея', measurements.first.neckCm!, null, tc),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (measurements.length >= 2) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: tc.card,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: tc.shadow(0.04), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Динамика замеров',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: tc.text)),
                  const SizedBox(height: 16),
                  if (measurements[0].chestCm != null && measurements[1].chestCm != null)
                    _buildMeasureRow('Грудь', measurements[0].chestCm!, measurements[1].chestCm!, tc),
                  if (measurements[0].waistCm != null && measurements[1].waistCm != null)
                    _buildMeasureRow('Талия', measurements[0].waistCm!, measurements[1].waistCm!, tc),
                  if (measurements[0].hipsCm != null && measurements[1].hipsCm != null)
                    _buildMeasureRow('Бёдра', measurements[0].hipsCm!, measurements[1].hipsCm!, tc),
                  if (measurements[0].leftArmCm != null && measurements[1].leftArmCm != null)
                    _buildMeasureRow('Рука', measurements[0].leftArmCm!, measurements[1].leftArmCm!, tc),
                  if (measurements[0].leftThighCm != null && measurements[1].leftThighCm != null)
                    _buildMeasureRow('Бедро', measurements[0].leftThighCm!, measurements[1].leftThighCm!, tc),
                  if (measurements[0].neckCm != null && measurements[1].neckCm != null)
                    _buildMeasureRow('Шея', measurements[0].neckCm!, measurements[1].neckCm!, tc),
                ],
              ),
            ),
          ],
        ] else ...[
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: tc.card,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Icon(Icons.straighten, size: 48, color: tc.textHint),
                const SizedBox(height: 16),
                Text('Пока нет замеров',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: tc.text)),
                const SizedBox(height: 8),
                Text('Запишите объёмы груди, талии, бёдер и рук',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: tc.textSecondary)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _showRecordMeasurementsDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: tc.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
          child: const Text('+ Записать замеры',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildMeasureRow(String label, double current, double? previous, ThemeColors tc) {
    final diff = previous != null ? current - previous : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: tc.text)),
          ),
          Text('${current.toStringAsFixed(0)} см',
              style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: tc.text)),
          const Spacer(),
          if (previous != null && diff != 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: diff < 0
                    ? const Color(0xFF75A47F).withValues(alpha: 0.12)
                    : Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    diff < 0 ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 10,
                    color: diff < 0 ? const Color(0xFF75A47F) : Colors.orange,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${diff.abs().toStringAsFixed(0)} см',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: diff < 0 ? const Color(0xFF75A47F) : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── TAB: % ЖИРА ───

  Widget _buildBodyFatTab(ThemeColors tc) {
    final entries = _userData.bodyFatEntries;

    return Column(
      children: [
        if (entries.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: tc.card,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: tc.shadow(0.04), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: [
                Text('% ЖИРА В ТЕЛЕ',
                    style: TextStyle(fontSize: 10, color: tc.textHint, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      entries.first.bodyFatPercent.toStringAsFixed(1),
                      style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w900, color: tc.text),
                    ),
                    const SizedBox(width: 4),
                    Text('%',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: tc.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF75A47F).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getBodyFatCategory(entries.first.bodyFatPercent),
                    style: const TextStyle(
                        color: Color(0xFF75A47F), fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),
                _buildBodyFatBar(tc, entries.first.bodyFatPercent),
              ],
            ),
          ),
          if (entries.length >= 2) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: tc.card,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: tc.shadow(0.04), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('История',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: tc.text)),
                  const SizedBox(height: 16),
                  ...entries.take(5).map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Text('${e.date.day}.${e.date.month}',
                            style: TextStyle(fontSize: 12, color: tc.textSecondary)),
                        const SizedBox(width: 16),
                        Text('${e.bodyFatPercent.toStringAsFixed(1)}%',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w900, fontSize: 16, color: tc.text)),
                        if (e.method != null) ...[
                          const SizedBox(width: 8),
                          Text('(${_methodLabel(e.method!)})',
                              style: TextStyle(fontSize: 10, color: tc.textHint)),
                        ],
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ] else ...[
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: tc.card,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Icon(Icons.monitor_heart_outlined, size: 48, color: tc.textHint),
                const SizedBox(height: 16),
                Text('Пока нет данных о % жира',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: tc.text)),
                const SizedBox(height: 8),
                Text('Запишите процент жира в теле, чтобы отслеживать изменения',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: tc.textSecondary)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _showRecordBodyFatDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: tc.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
          child: const Text('+ Записать % жира',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  String _methodLabel(String method) {
    switch (method) {
      case 'caliper':
        return 'калипер';
      case 'scale':
        return 'весы';
      default:
        return 'вручную';
    }
  }

  Widget _buildBodyFatBar(ThemeColors tc, double percent) {
    final pct = percent.clamp(5, 40);
    final fraction = (pct - 5) / 35;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(height: 12, color: tc.text.withValues(alpha: 0.08)),
              FractionallySizedBox(
                widthFactor: fraction,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF75A47F), const Color(0xFFFF9800), const Color(0xFFE53935)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('5%', style: TextStyle(fontSize: 9, color: tc.textHint)),
            Text('15%', style: TextStyle(fontSize: 9, color: tc.textHint)),
            Text('25%', style: TextStyle(fontSize: 9, color: tc.textHint)),
            Text('40%+', style: TextStyle(fontSize: 9, color: tc.textHint)),
          ],
        ),
      ],
    );
  }

  String _getBodyFatCategory(double percent) {
    if (percent < 10) return '⚡ Экстремально низкий';
    if (percent < 15) return '💪 Спортивный';
    if (percent < 20) return '✅ Нормальный';
    if (percent < 25) return '📈 Выше нормы';
    return '⚠️ Высокий';
  }

  // ─── HEATMAP (выровнен по неделям, начинается с понедельника) ───

  Widget _buildActivityHeatmap(ThemeColors tc) {
    final activeDays = _userData.activeDays;
    final now = DateTime.now();

    // Последние 4 полные недели, начиная с понедельника
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final start = monday.subtract(const Duration(days: 21));
    final days = List.generate(28, (i) => start.add(Duration(days: i)));

    final activeCount =
        activeDays.where((d) => d.isAfter(start.subtract(const Duration(days: 1)))).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: tc.shadow(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Последние 28 дней',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: tc.text)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF75A47F).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$activeCount записей',
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF75A47F))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Названия месяцев
          Row(
            children: List.generate(28, (i) {
              final day = days[i];
              final isMonthStart = i == 0 || day.month != days[i - 1].month;
              return Expanded(
                child: Text(
                  isMonthStart ? _getMonthName(day) : '',
                  style: TextStyle(fontSize: 9, color: tc.textHint, fontWeight: FontWeight.w700),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          // Дни недели
          Row(
            children: ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС']
                .map((d) => Expanded(
                      child: Text(d,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 8, color: tc.textHint, fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          // Сетка 4×7
          ...List.generate(4, (row) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: List.generate(7, (col) {
                final idx = row * 7 + col;
                final day = days[idx];
                final isActive = activeDays.any((d) =>
                    d.year == day.year && d.month == day.month && d.day == day.day);
                final isToday = day.year == now.year &&
                    day.month == now.month &&
                    day.day == now.day;

                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 28,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isToday
                          ? tc.primary
                          : isActive
                              ? const Color(0xFF75A47F).withValues(alpha: 0.75)
                              : tc.text.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: isToday
                          ? Border.all(
                              color: tc.text.withValues(alpha: 0.6), width: 1.5)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: isToday
                        ? Text('${day.day}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800))
                        : (isActive
                            ? Text('${day.day}',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600))
                            : null),
                  ),
                );
              }),
            ),
          )),
          const SizedBox(height: 12),
          // Легенда
          Row(
            children: [
              _buildLegendItem(tc, const Color(0xFF75A47F), 'есть запись'),
              const SizedBox(width: 14),
              _buildLegendItem(tc, tc.primary, 'сегодня'),
              const Spacer(),
              Icon(Icons.touch_app_outlined, size: 12, color: tc.textHint),
              const SizedBox(width: 4),
              Text('дни с записями подсвечены',
                  style: TextStyle(fontSize: 10, color: tc.textHint, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(ThemeColors tc, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: tc.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ─── CHIP ───

  Widget _buildChip(String label, bool isSelected) {
    final tc = ThemeColors.of(context);
    return GestureDetector(
      onTap: () => setState(() => _selectedChip = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? tc.primary : tc.card,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: tc.divider),
        ),
        child: Text(label,
            style: TextStyle(
              color: isSelected ? Colors.white : tc.textSecondary,
              fontWeight: FontWeight.bold, fontSize: 13,
            )),
      ),
    );
  }

  String _getMonthName(DateTime date) {
    const months = [
      'Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн',
      'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'
    ];
    return months[date.month - 1];
  }
}

// ─── CHART PAINTER ───

class ProgressChartPainter extends CustomPainter {
  final List<double> weightHistory;
  final Color color;

  ProgressChartPainter({required this.weightHistory, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (weightHistory.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF75A47F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final minWeight = weightHistory.reduce((a, b) => a < b ? a : b);
    final maxWeight = weightHistory.reduce((a, b) => a > b ? a : b);
    final range = (maxWeight - minWeight).clamp(1.0, double.infinity);

    final path = Path();
    final stepX = size.width / (weightHistory.length - 1);

    for (int i = 0; i < weightHistory.length; i++) {
      final x = i * stepX;
      final y = size.height -
          ((weightHistory[i] - minWeight) / range) * (size.height * 0.8) -
          size.height * 0.1;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw dots
    final dotPaint = Paint()..color = const Color(0xFF75A47F);
    final lastX = (weightHistory.length - 1) * stepX;
    final lastY = size.height -
        ((weightHistory.last - minWeight) / range) * (size.height * 0.8) -
        size.height * 0.1;
    canvas.drawCircle(Offset(lastX, lastY), 6, dotPaint);
    canvas.drawCircle(Offset(lastX, lastY), 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant ProgressChartPainter oldDelegate) =>
      oldDelegate.weightHistory != weightHistory;
}
