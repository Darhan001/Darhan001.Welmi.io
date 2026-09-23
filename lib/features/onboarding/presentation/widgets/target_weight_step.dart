import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/theme_colors.dart';

class TargetWeightStep extends StatefulWidget {
  final double currentWeight;
  final double targetWeight;
  final ValueChanged<double> onTargetChanged;

  const TargetWeightStep({
    super.key,
    required this.currentWeight,
    required this.targetWeight,
    required this.onTargetChanged,
  });

  @override
  State<TargetWeightStep> createState() => _TargetWeightStepState();
}

class _TargetWeightStepState extends State<TargetWeightStep> {
  late FixedExtentScrollController _scrollController;
  late int _selectedIndex;
  late List<int> _weightOptions;

  @override
  void initState() {
    super.initState();
    _weightOptions = List.generate(
      151,
      (i) => (widget.currentWeight - 30 + i).round(),
    ).where((w) => w >= 30 && w <= 250).toList();

    final initialTarget = widget.targetWeight.round();
    _selectedIndex = _weightOptions.indexOf(initialTarget);
    if (_selectedIndex < 0) _selectedIndex = 30;
    _scrollController = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final diff = (widget.currentWeight - widget.targetWeight).round();
    final diffText = diff > 0 ? '-$diff кг от текущего веса' : '+${diff.abs()} кг от текущего веса';

    return Column(
      children: [
        const SizedBox(height: 40),
        Text(
          'Какой вес хочешь\nдостичь?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Установи цель, к которой мы будем стремиться',
          textAlign: TextAlign.center,
          style: TextStyle(color: tc.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 60),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 70,
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: tc.card,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              ListWheelScrollView(
                controller: _scrollController,
                itemExtent: 60,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedIndex = index;
                    widget.onTargetChanged(
                        _weightOptions[index].toDouble());
                  });
                },
                children: _weightOptions.map((w) {
                  return _buildWeightListItem(
                    w.toString(),
                    w == _weightOptions[_selectedIndex],
                    tc,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: tc.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 14, color: tc.textSecondary),
              const SizedBox(width: 6),
              Text(
                diffText,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: tc.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeightListItem(String value, bool isSelected, ThemeColors tc) {
    return Center(
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: value,
              style: GoogleFonts.inter(
                fontSize: isSelected ? 40 : 32,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                color: isSelected ? tc.text : tc.textHint,
              ),
            ),
            if (isSelected)
              TextSpan(
                text: ' кг',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: tc.text,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
