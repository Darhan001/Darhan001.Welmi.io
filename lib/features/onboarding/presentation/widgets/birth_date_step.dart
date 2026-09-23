import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';

class BirthDateStep extends StatelessWidget {
  final DateTime birthDate;
  final ValueChanged<DateTime> onDateChanged;

  const BirthDateStep({
    super.key,
    required this.birthDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            'Когда ты родился?',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Эта информация поможет нам точнее\nрассчитать твою норму калорий',
            textAlign: TextAlign.center,
            style: TextStyle(color: tc.textSecondary, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 60),
          Expanded(
            child: CupertinoTheme(
              data: CupertinoThemeData(
                brightness: tc.isDark ? Brightness.dark : Brightness.light,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(
                    fontSize: 22,
                    color: tc.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: birthDate,
                minimumYear: 1950,
                maximumYear: DateTime.now().year,
                onDateTimeChanged: onDateChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
