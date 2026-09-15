import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/vajra_colors.dart';

class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (Navigator.of(context).canPop())
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.arrowLeft, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Back', style: TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              const Text(
                'Agent Activity Log',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Audit history of autonomous actions, tool executions, and memory updates performed by VAJRA.',
                style: TextStyle(color: VajraColors.secondaryText, fontSize: 14),
              ),
              const SizedBox(height: 28),
              _buildTimelineItem(
                time: '10:32 PM',
                title: 'Created Study Milestone',
                description: 'Decomposed Physics exam goal into 4 daily planner tasks.',
                icon: LucideIcons.calendarCheck,
              ),
              const SizedBox(height: 12),
              _buildTimelineItem(
                time: '10:15 PM',
                title: 'Browser Navigation Request',
                description: 'Executed browser.open_url intent for study resources.',
                icon: LucideIcons.globe,
              ),
              const SizedBox(height: 12),
              _buildTimelineItem(
                time: '09:40 PM',
                title: 'Saved Personal Preference',
                description: 'Memory classified as PREFERENCE: "Night study sessions".',
                icon: LucideIcons.brain,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white70, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text(time, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
