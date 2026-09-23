import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool showArrow;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (showArrow) ...[
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 20),
          ]
        ],
      ),
    );
  }
}
