import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WaterTrackerPage extends StatefulWidget {
  const WaterTrackerPage({super.key});

  @override
  State<WaterTrackerPage> createState() => _WaterTrackerPageState();
}

class _WaterTrackerPageState extends State<WaterTrackerPage> {
  int _currentWater = 1300;
  final int _dailyGoal = 2000;
  final List<double> _weeklyProgress = [0.4, 0.6, 0.8, 0.5, 0.9, 0.3, 0.7];

  void _addWater(int amount) {
    setState(() {
      _currentWater = (_currentWater + amount).clamp(0, _dailyGoal * 2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (_dailyGoal - _currentWater).clamp(0, _dailyGoal);
    final progress = _currentWater / _dailyGoal;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back, size: 28),
                    ),
                  ),
                  Text('Вода',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, fontSize: 18)),
                  const Icon(Icons.notifications_none, size: 28),
                ],
              ),
              const SizedBox(height: 40),
              const Text('Выпито сегодня',
                  style: TextStyle(
                      color: Colors.black38,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$_currentWater',
                      style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.black),
                    ),
                    TextSpan(
                      text: ' / $_dailyGoal мл',
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black26),
                    ),
                  ],
                ),
              ),
              Text('Осталось $remaining мл до цели',
                  style: const TextStyle(
                      color: Colors.black26,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 40),
              Expanded(
                child: Container(
                  width: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 20)
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 400),
                        heightFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F3E5),
                            borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(40)),
                          ),
                        ),
                      ),
                      if (_currentWater >= _dailyGoal)
                        const Positioned(
                          top: 20,
                          child: Icon(Icons.check_circle,
                              color: Color(0xFF75A47F), size: 40),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: _buildWaterActionButton(
                        250, 'Стакан', Icons.opacity, false),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildWaterActionButton(
                        500, 'Бутылка', Icons.local_drink, true),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Неделя',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.black26)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDayBar('ПН', _weeklyProgress[0]),
                  _buildDayBar('ВТ', _weeklyProgress[1]),
                  _buildDayBar('СР', _weeklyProgress[2]),
                  _buildDayBar('ЧТ', _weeklyProgress[3]),
                  _buildDayBar('ПТ', _weeklyProgress[4]),
                  _buildDayBar('СБ', _weeklyProgress[5]),
                  _buildDayBar('ВС', _weeklyProgress[6]),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaterActionButton(
      int amount, String label, IconData icon, bool isDark) {
    return GestureDetector(
      onTap: () => _addWater(amount),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isDark
                    ? Colors.white
                    : const Color(0xFF75A47F),
                size: 24),
            const SizedBox(height: 16),
            Text('+$amount мл',
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 18)),
            Text(label,
                style: const TextStyle(
                    color: Colors.black26,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildDayBar(String day, double progress) {
    return Column(
      children: [
        Container(
          height: 60,
          width: 8,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 60 * progress,
            decoration: BoxDecoration(
              color: const Color(0xFF75A47F).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(day,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.black26)),
      ],
    );
  }
}
