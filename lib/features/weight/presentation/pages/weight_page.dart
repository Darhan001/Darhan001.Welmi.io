import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/services/user_data_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/services/units_service.dart';
import 'package:lumina/core/widgets/app_snackbar.dart';
import 'package:lumina/core/widgets/units_format.dart';
import 'package:lumina/features/weight/presentation/widgets/record_weight_sheet.dart';
import 'package:lumina/l10n/app_localizations.dart';

class WeightPage extends StatefulWidget {
  const WeightPage({super.key});

  @override
  State<WeightPage> createState() => _WeightPageState();
}

class _WeightPageState extends State<WeightPage>
    with SingleTickerProviderStateMixin {
  final UserDataService _userData = UserDataService();
  late AnimationController _chartController;

  @override
  void initState() {
    super.initState();
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _loadData();
  }

  @override
  void dispose() {
    _chartController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _userData.loadAll();
    if (mounted) setState(() {});
  }

  Future<void> _showRecordWeightDialog() async {
    final loc = AppLocalizations.of(context)!;
    final saved = await showRecordWeightSheet(
      context,
      initialKg: _userData.latestWeight,
      onSave: _userData.saveWeight,
    );
    if (!saved || !mounted) return;
    _chartController
      ..reset()
      ..forward();
    setState(() {});
    AppSnackbar.success(context, loc.weightSaved);
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return ListenableBuilder(
      // Единицы могут смениться в настройках, пока экран жив в IndexedStack.
      listenable: Listenable.merge([_userData, UnitsService.instance]),
      builder: (context, _) {
        final currentWeight = _userData.latestWeight ?? 0.0;
        final startWeight = _userData.startWeight ?? currentWeight;
        final goalWeight = _userData.goalWeight ?? 0.0;
        final totalLoss = startWeight - currentWeight;
        final entries = _userData.weightEntries;
        final weights = entries.reversed.map((e) => e.weightKg).toList();

        return Scaffold(
          backgroundColor: tc.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: tc.card,
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.arrow_back,
                              size: 22, color: tc.text),
                        ),
                      ),
                      Text(AppLocalizations.of(context)!.weightTitle,
                          style: GoogleFonts.notoSerif(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: tc.text)),
                      GestureDetector(
                        onTap: () => _showRecordWeightDialog(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: tc.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.add,
                              color: tc.textOnPrimary, size: 22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Main weight card
                  _buildWeightCard(
                      tc, currentWeight, startWeight, goalWeight, totalLoss),
                  const SizedBox(height: 24),

                  // Chart
                  if (weights.length >= 2) ...[
                    _buildChartCard(tc, weights),
                    const SizedBox(height: 24),
                  ],

                  // Stats row
                  _buildStatsRow(tc, totalLoss, goalWeight, currentWeight),
                  const SizedBox(height: 24),

                  // Weekly mini stats
                  if (weights.length >= 2)
                    _buildWeeklyChangeCard(tc, weights),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeightCard(ThemeColors tc, double current, double start,
      double goal, double loss) {
    final progress =
        goal > 0 && start > goal ? ((start - current) / (start - goal)).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: tc.shadow(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [               _buildInfo(tc, AppLocalizations.of(context)!.startWeight, AppLocalizations.of(context)!.formatWeight(start)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: loss > 0
                      ? const Color(0xFFE8F3E5)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      loss > 0 ? Icons.arrow_downward : Icons.arrow_upward,
                      size: 14,
                      color: loss > 0
                          ? const Color(0xFF75A47F)
                          : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      // Направление показывает стрелка рядом, поэтому выводим модуль:
                      // раньше при наборе веса получалось «+-1.2 кг».
                      AppLocalizations.of(context)!.formatWeight(loss.abs()),
                      style: TextStyle(
                        color: loss > 0
                            ? const Color(0xFF75A47F)
                            : Colors.orange,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),               _buildInfo(tc, AppLocalizations.of(context)!.goalWeight, AppLocalizations.of(context)!.formatWeight(goal)),
            ],
          ),
          const SizedBox(height: 24),
          Text(current.toStringAsFixed(1),
              style: GoogleFonts.inter(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: tc.text)),           Text(AppLocalizations.of(context)!.currentWeightKg,
              style: TextStyle(
                  fontSize: 12,
                  color: tc.textHint,
                  fontWeight: FontWeight.w600)),
          if (goal > 0 && start > goal) ...[
            const SizedBox(height: 16),
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: tc.text.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF75A47F),
                        Color(0xFF4A8C5C)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),               Text(AppLocalizations.of(context)!.percentToGoal((progress * 100).toStringAsFixed(0)),
                style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF75A47F),
                    fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }

  Widget _buildChartCard(ThemeColors tc, List<double> weights) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: tc.shadow(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [               Text(AppLocalizations.of(context)!.weightDynamics,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: tc.text)),               Text(AppLocalizations.of(context)!.weightEntries(weights.length),
                  style: TextStyle(
                      fontSize: 11, color: tc.textHint, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _chartController,
              builder: (context, child) {
                return CustomPaint(
                  painter: WeightChartPainter(
                    weightHistory: weights,
                    color: tc.primary,
                    animationValue: _chartController.value,
                  ),
                  size: const Size(double.infinity, 200),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(_userData.weightEntries.last.date),
                style: TextStyle(fontSize: 10, color: tc.textHint),
              ),
              Text(
                _formatDate(_userData.weightEntries.first.date),
                style: TextStyle(fontSize: 10, color: tc.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChangeCard(ThemeColors tc, List<double> weights) {
    // Вычисляем изменение за последние 7 дней
    final recent = weights.length >= 7 ? weights.sublist(weights.length - 7) : weights;
    final weeklyChange = recent.last - recent.first;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: tc.shadow(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: weeklyChange <= 0
                  ? const Color(0xFFE8F3E5)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              weeklyChange <= 0
                  ? Icons.trending_down
                  : Icons.trending_up,
              color: weeklyChange <= 0
                  ? const Color(0xFF75A47F)
                  : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [                 Text(AppLocalizations.of(context)!.weekChange(recent.length),
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: tc.text)),
                Text(
                  weeklyChange <= 0                       ? AppLocalizations.of(context)!.weekLost(weeklyChange.abs().toStringAsFixed(1))
                       : AppLocalizations.of(context)!.weekGained(weeklyChange.toStringAsFixed(1)),
                  style: TextStyle(
                    fontSize: 12,
                    color: weeklyChange <= 0
                        ? const Color(0xFF75A47F)
                        : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            AppLocalizations.of(context)!.formatWeight(weeklyChange, signed: true),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: weeklyChange <= 0
                  ? const Color(0xFF75A47F)
                  : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(ThemeColors tc, String label, String value) {
    return Column(children: [
      Text(value,
          style: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.w800, color: tc.text)),
      Text(label,
          style: TextStyle(
              fontSize: 10,
              color: tc.textHint,
              fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _buildStatsRow(
      ThemeColors tc, double loss, double goal, double current) {
    final toGoal = (current - goal).clamp(0, 999);
    return Row(
      children: [
        Expanded(
            child: _buildMiniStat(                 tc, AppLocalizations.of(context)!.weightLost, AppLocalizations.of(context)!.formatWeight(loss),
                Icons.trending_down, const Color(0xFF75A47F))),
        const SizedBox(width: 12),
        Expanded(
            child: _buildMiniStat(                 tc, AppLocalizations.of(context)!.weightToGoal, AppLocalizations.of(context)!.formatWeight(toGoal.toDouble()),
                Icons.flag_rounded, Colors.orange)),
      ],
    );
  }

  Widget _buildMiniStat(ThemeColors tc, String label, String value,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: tc.shadow(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w900, color: tc.text)),
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  color: tc.textHint,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

// ─── CHART PAINTER ───

class WeightChartPainter extends CustomPainter {
  final List<double> weightHistory;
  final Color color;
  final double animationValue;

  WeightChartPainter({
    required this.weightHistory,
    required this.color,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weightHistory.length < 2) return;

    final chartHeight = size.height * 0.85;
    final topMargin = size.height * 0.15;

    final minWeight = weightHistory.reduce((a, b) => a < b ? a : b);
    final maxWeight = weightHistory.reduce((a, b) => a > b ? a : b);
    final range = (maxWeight - minWeight).clamp(0.5, double.infinity);

    // Padding
    const leftPad = 0.0;
    const rightPad = 0.0;
    final chartWidth = size.width - leftPad - rightPad;

    // Grid lines
    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = topMargin + (chartHeight / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Gradient fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.2),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath = Path();

    // Line
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final itemsToShow = (weightHistory.length * animationValue).ceil().clamp(2, weightHistory.length);
    final visibleWeights = weightHistory.sublist(0, itemsToShow);
    if (visibleWeights.length < 2) return;

    final vStepX = chartWidth / (visibleWeights.length - 1);
    final path = Path();

    for (int i = 0; i < visibleWeights.length; i++) {
      final x = leftPad + i * vStepX;
      final y = topMargin +
          chartHeight -
          ((visibleWeights[i] - minWeight) / range) * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else if (i < visibleWeights.length - 1) {
        // Smooth curve using quadratic bezier
        final prevX = leftPad + (i - 1) * vStepX;
        final midX = (prevX + x) / 2;
        final prevY = topMargin +
            chartHeight -
            ((visibleWeights[i - 1] - minWeight) / range) * chartHeight;
        path.quadraticBezierTo(prevX, prevY, midX, (prevY + y) / 2);
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    canvas.drawPath(fillPath, fillPaint);

    // Draw the line
    if (animationValue >= 0.05) {
      canvas.drawPath(path, linePaint);
    }

    // Draw dots for each point
    for (int i = 0; i < visibleWeights.length; i++) {
      final x = leftPad + i * vStepX;
      final y = topMargin +
          chartHeight -
          ((visibleWeights[i] - minWeight) / range) * chartHeight;

      final isLast = i == visibleWeights.length - 1;
      canvas.drawCircle(
        Offset(x, y),
        isLast ? 6 : 3,
        Paint()
          ..color = isLast ? Colors.white : color.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill,
      );
      if (isLast) {
        canvas.drawCircle(
          Offset(x, y),
          4,
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant WeightChartPainter oldDelegate) =>
      oldDelegate.weightHistory != weightHistory ||
      oldDelegate.animationValue != animationValue;
}
