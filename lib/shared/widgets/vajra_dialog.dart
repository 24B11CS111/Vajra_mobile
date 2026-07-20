import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/vajra_colors.dart';
import 'vajra_button.dart';

class VajraDialog extends StatelessWidget {
  final String title;
  final String content;
  final String primaryButtonText;
  final VoidCallback onPrimaryPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;

  const VajraDialog({
    super.key,
    required this.title,
    required this.content,
    required this.primaryButtonText,
    required this.onPrimaryPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
  });

  static void show(BuildContext context, {
    required String title,
    required String content,
    required String primaryButtonText,
    required VoidCallback onPrimaryPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.8),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: VajraDialog(
              title: title,
              content: content,
              primaryButtonText: primaryButtonText,
              onPrimaryPressed: onPrimaryPressed,
              secondaryButtonText: secondaryButtonText,
              onSecondaryPressed: onSecondaryPressed,
            ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms).fadeIn(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: VajraColors.elevatedSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: VajraColors.glassBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.displayMedium, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(content, style: const TextStyle(color: VajraColors.secondaryText, fontSize: 16), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Row(
            children: [
              if (secondaryButtonText != null) ...[
                Expanded(
                  child: VajraButton(
                    text: secondaryButtonText!,
                    type: VajraButtonType.secondary,
                    onPressed: onSecondaryPressed ?? () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: VajraButton(
                  text: primaryButtonText,
                  onPressed: onPrimaryPressed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

