import 'package:flutter/material.dart';

class OnboardingProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const OnboardingProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    double progress = (currentStep + 1) / totalSteps;
    return Stack(
      children: [
        Container(
          height: 2,
          width: double.infinity,
          color: Colors.black12,
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 2,
          width: MediaQuery.of(context).size.width * progress,
          color: Colors.black,
        ),
      ],
    );
  }
}
