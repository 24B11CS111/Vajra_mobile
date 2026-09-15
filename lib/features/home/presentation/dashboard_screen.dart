import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../planner/providers/planner_provider.dart';
import '../../study/providers/study_provider.dart';
import '../../profile/providers/profile_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final tasksState = ref.watch(plannerProvider);
    final assignmentsState = ref.watch(assignmentsProvider);
    final subjectsState = ref.watch(subjectsProvider);

    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    final userName = profileState.valueOrNull?.name ?? 'Student';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      body: SafeArea(
        child: RefreshIndicator(
          color: Colors.purpleAccent,
          onRefresh: () async {
            ref.read(profileProvider.notifier).refresh();
            ref.read(plannerProvider.notifier).loadTasks();
            ref.read(assignmentsProvider.notifier).loadAssignments();
            ref.read(subjectsProvider.notifier).loadSubjects();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      timeGreeting.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.purpleAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.brain, color: Colors.white, size: 20),
                          tooltip: 'Memory Vault',
                          onPressed: () => context.push('/memory'),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.bell, color: Colors.white, size: 20),
                          tooltip: 'Notifications',
                          onPressed: () => context.push('/notifications'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Greeting & Headline
                Text(
                  'Welcome, $userName.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Quick Ask VAJRA Card (AI Companion Entrypoint)
                _buildAICalloutCard(context),
                const SizedBox(height: 20),

                // Metrics / Study Progress Overview
                _buildStudyProgressSection(tasksState, assignmentsState),
                const SizedBox(height: 24),

                // Today's Action Tasks
                _buildTasksPreviewSection(context, ref, tasksState),
                const SizedBox(height: 24),

                // Upcoming Assignments & Deadlines
                _buildAssignmentsPreviewSection(context, assignmentsState),
                const SizedBox(height: 24),

                // Upcoming Exams Section
                _buildExamsSection(subjectsState),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAICalloutCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/chat'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E1065), Color(0xFF1E1B4B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purpleAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.sparkles, color: Colors.purpleAccent, size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ask VAJRA AI',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Create assignments, schedule sessions, or ask any question',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyProgressSection(
    AsyncValue<List<dynamic>> tasksState,
    AsyncValue<List<dynamic>> assignmentsState,
  ) {
    final tasks = tasksState.valueOrNull ?? [];
    final assignments = assignmentsState.valueOrNull ?? [];

    final completedTasks = tasks.where((t) => t.isCompleted == true).length;
    final totalTasks = tasks.length;
    final completedAssignments = assignments.where((a) => a.status == 'COMPLETED').length;
    final totalAssignments = assignments.length;

    final totalItems = totalTasks + totalAssignments;
    final completedItems = completedTasks + completedAssignments;
    final progress = totalItems > 0 ? (completedItems / totalItems) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daily Completion', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.purpleAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            color: Colors.purpleAccent,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$completedTasks of $totalTasks tasks done', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              Text('$completedAssignments of $totalAssignments assignments done', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTasksPreviewSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<dynamic>> tasksState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Today's Tasks", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () => context.go('/planner'),
              child: const Text('View All', style: TextStyle(color: Colors.purpleAccent, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        tasksState.when(
          data: (tasks) {
            if (tasks.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF141418), borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Text('No tasks for today. Tap planner to add one!', style: TextStyle(color: Colors.white38))),
              );
            }
            return Column(
              children: tasks.take(3).map((t) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141418),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => ref.read(plannerProvider.notifier).toggleCompletion(t.id),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: t.isCompleted ? Colors.greenAccent : Colors.transparent,
                            border: Border.all(color: t.isCompleted ? Colors.greenAccent : Colors.white38, width: 2),
                          ),
                          child: t.isCompleted ? const Icon(Icons.check, size: 14, color: Colors.black) : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.title,
                          style: TextStyle(
                            color: t.isCompleted ? Colors.white38 : Colors.white,
                            fontSize: 14,
                            decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
          error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _buildAssignmentsPreviewSection(
    BuildContext context,
    AsyncValue<List<dynamic>> assignmentsState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Upcoming Assignments', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () => context.go('/study'),
              child: const Text('View All', style: TextStyle(color: Colors.purpleAccent, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        assignmentsState.when(
          data: (assignments) {
            final active = assignments.where((a) => a.status != 'COMPLETED').toList();
            if (active.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF141418), borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Text('All caught up! No pending assignments.', style: TextStyle(color: Colors.white38))),
              );
            }
            return Column(
              children: active.take(2).map((a) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141418),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.fileText, color: Colors.blueAccent, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              '${a.subjectName} • Due ${a.dueDate != null ? DateFormat('MMM d').format(a.dueDate!) : 'Soon'}',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
          error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _buildExamsSection(AsyncValue<List<dynamic>> subjectsState) {
    return subjectsState.when(
      data: (subjects) {
        final withExams = subjects.where((s) => s.examDate != null).toList();
        if (withExams.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upcoming Exams', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...withExams.map((s) {
              final daysLeft = s.examDate!.difference(DateTime.now()).inDays;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141418),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Date: ${DateFormat('MMM d, yyyy').format(s.examDate!)}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        daysLeft >= 0 ? '$daysLeft days left' : 'Completed',
                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
