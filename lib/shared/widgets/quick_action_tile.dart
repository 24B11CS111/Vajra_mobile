import 'package:flutter/material.dart';
import '../../core/theme/vajra_colors.dart';

class QuickActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<QuickActionTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VajraColors.elevatedSurface,
                border: Border.all(color: VajraColors.glassBorder),
              ),
              child: Icon(widget.icon, color: VajraColors.primaryText),
            ),
            const SizedBox(height: 8),
            Text(widget.label, style: const TextStyle(fontSize: 12, color: VajraColors.secondaryText)),
          ],
        ),
      ),
    );
  }
}
