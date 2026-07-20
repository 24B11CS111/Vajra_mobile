import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/home_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefingAsync = ref.watch(briefingProvider);
    final isMorning = DateTime.now().hour < 17;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: briefingAsync.when(
          data: (briefing) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMorning ? briefing.title : 'Evening Reflection',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isMorning ? briefing.message : briefing.eveningWrapUp,
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w300, height: 1.2),
                  ),
                  const SizedBox(height: 48),
                  if (isMorning) ...[
                    _buildIntelligentCard(
                      icon: LucideIcons.cloudSun,
                      title: 'Weather Context',
                      subtitle: briefing.weatherContext,
                    ),
                    const SizedBox(height: 16),
                    _buildIntelligentCard(
                      icon: LucideIcons.calendar,
                      title: briefing.priorityTaskTitle,
                      subtitle: briefing.priorityTaskSubtitle,
                    ),
                  ] else ...[
                    _buildIntelligentCard(
                      icon: LucideIcons.brain,
                      title: 'Daily Wrap-up',
                      subtitle: 'How did the Quantum Physics Revision go?',
                    ),
                  ],
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
          error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        ),
      ),
    );
  }

  Widget _buildIntelligentCard({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

