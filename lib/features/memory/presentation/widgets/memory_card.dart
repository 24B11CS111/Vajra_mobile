import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/memory_model.dart';
import '../../providers/memory_provider.dart';
import 'package:intl/intl.dart';

class MemoryCard extends ConsumerWidget {
  final MemoryModel memory;

  const MemoryCard({super.key, required this.memory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  memory.category,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
              ),
              Row(
                children: [
                  if (memory.importanceScore > 0.8)
                    const Icon(LucideIcons.flame, color: Colors.orangeAccent, size: 14),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => ref.read(memoryProvider.notifier).togglePin(memory.id),
                    child: Icon(
                      memory.isPinned ? LucideIcons.pin : LucideIcons.pinOff,
                      color: memory.isPinned ? Colors.white : Colors.grey[800],
                      size: 16,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(
            memory.content,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateFormat.format(memory.createdAt),
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
              Text(
                memory.source,
                style: TextStyle(color: Colors.grey[800], fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

