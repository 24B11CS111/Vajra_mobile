import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/vajra_colors.dart';

class VajraProgressIndicator extends StatelessWidget {
  final double progress; // 0.0 to 1.0

  const VajraProgressIndicator({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: VajraColors.primaryText.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: VajraColors.accent,
            borderRadius: BorderRadius.circular(4),
          ),
        ).animate().scaleX(begin: 0, end: 1, duration: 600.ms, curve: Curves.easeOutCirc, alignment: Alignment.centerLeft),
      ),
    );
  }
}

