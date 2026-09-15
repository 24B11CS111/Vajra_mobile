import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/planner_model.dart';
import '../../providers/planner_provider.dart';
import 'package:intl/intl.dart';

class PlannerTaskCard extends ConsumerWidget {
  final PlannerTask task;

  const PlannerTaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFormat = DateFormat('h:mm a');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => ref.read(plannerProvider.notifier).toggleCompletion(task.id),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: task.isCompleted ? Colors.green : Colors.grey[600]!),
                    color: task.isCompleted ? Colors.green.withValues(alpha: 0.2) : Colors.transparent,
                  ),
                  child: task.isCompleted ? const Icon(LucideIcons.check, size: 12, color: Colors.green) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    color: task.isCompleted ? Colors.grey[600] : Colors.white,
                    fontSize: 16,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
              ),
              const Icon(LucideIcons.gripVertical, color: Colors.grey, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(LucideIcons.clock, color: Colors.grey[500], size: 12),
              const SizedBox(width: 4),
              Text(
                "${timeFormat.format(task.startTime)} - ${timeFormat.format(task.endTime)}",
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.category,
                  style: const TextStyle(color: Colors.white, fontSize: 9, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          if (task.aiSuggestion != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.sparkles, color: Colors.blueAccent, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.aiSuggestion!,
                      style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}

