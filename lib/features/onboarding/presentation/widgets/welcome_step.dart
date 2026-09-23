import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/theme_colors.dart';

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: tc.card,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: tc.shadow(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Icon(Icons.restaurant_menu, size: 32, color: tc.text),
          ),
          const SizedBox(height: 48),
          Text(
            'Добро\nпожаловать!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 20),
          Text(
            'Ответь на несколько вопросов, и мы составим твой персональный план питания',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: tc.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
