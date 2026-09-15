import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/vajra_colors.dart';

enum VajraButtonType { primary, secondary, ghost }

class VajraButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final VajraButtonType type;
  final bool isLoading;
  final IconData? icon;

  const VajraButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = VajraButtonType.primary,
    this.isLoading = false,
    this.icon,
  });

  @override
  State<VajraButton> createState() => _VajraButtonState();
}

class _VajraButtonState extends State<VajraButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Border? border;

    switch (widget.type) {
      case VajraButtonType.primary:
        backgroundColor = VajraColors.accent;
        textColor = VajraColors.primaryBackground;
        break;
      case VajraButtonType.secondary:
        backgroundColor = Colors.transparent;
        textColor = VajraColors.primaryText;
        border = Border.all(color: VajraColors.primaryText.withValues(alpha: 0.5));
        break;
      case VajraButtonType.ghost:
        backgroundColor = Colors.transparent;
        textColor = VajraColors.primaryText;
        break;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (!widget.isLoading) widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: 150.ms,
        curve: Curves.easeOutQuad,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(28),
            border: border,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: textColor,
                      strokeWidth: 2,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: textColor, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            widget.text,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

