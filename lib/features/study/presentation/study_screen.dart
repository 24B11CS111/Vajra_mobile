import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/study_provider.dart';

class StudyScreen extends ConsumerWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studyState = ref.watch(studyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Study Assistant', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w300, letterSpacing: -1)),
              const SizedBox(height: 32),
              _buildExamCountdown(),
              const SizedBox(height: 32),
              const Text('AI Recommendations', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              _buildRecommendationCard(
                icon: LucideIcons.brain,
                title: 'Data Structures Revision',
                subtitle: 'Your weakest topics are Trees and Graphs.',
                color: Colors.purpleAccent,
              ),
              const SizedBox(height: 12),
              _buildRecommendationCard(
                icon: LucideIcons.bookOpen,
                title: 'Physics Mock Test',
                subtitle: 'Scheduled for tomorrow. Start PYQs now?',
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 32),
              const Text('Upcoming Sessions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              studyState.when(
                data: (sessions) {
                  if (sessions.isEmpty) return const Text('No upcoming sessions.', style: TextStyle(color: Colors.grey));
                  return Column(
                    children: sessions.map((session) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(session.subject, style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(session.topic, style: const TextStyle(color: Colors.white, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text('${session.durationMinutes} mins', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                              ],
                            ),
                            Text(DateFormat('E, MMM d').format(session.scheduledTime), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 32),
              const Text('Modules', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildModuleCard(LucideIcons.library, 'Subjects'),
                  _buildModuleCard(LucideIcons.fileText, 'Assignments'),
                  _buildModuleCard(LucideIcons.copy, 'Flashcards'),
                  _buildModuleCard(LucideIcons.activity, 'Analytics'),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamCountdown() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Physics Midterm', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('In 3 days', style: TextStyle(color: Colors.redAccent.withValues(alpha: 0.8), fontSize: 14)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.clock, color: Colors.redAccent, size: 20),
          )
        ],
      ),
    );
  }

  Widget _buildRecommendationCard({required IconData icon, required String title, required String subtitle, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildModuleCard(IconData icon, String title) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}

