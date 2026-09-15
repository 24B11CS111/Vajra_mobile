import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/vajra_offline_banner.dart';
import '../providers/study_provider.dart';

class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({super.key});

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0C),
        elevation: 0,
        title: const Text(
          'Study Hub',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, color: Colors.purpleAccent, size: 24),
            onPressed: () {
              if (_tabController.index == 0) {
                _showAddAssignmentDialog();
              } else if (_tabController.index == 1) {
                _showAddSubjectDialog();
              } else {
                _showAddAssignmentDialog();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purpleAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Assignments'),
            Tab(text: 'Subjects'),
            Tab(text: 'Sessions'),
          ],
        ),
      ),
      body: Column(
        children: [
          const VajraOfflineBanner(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAssignmentsTab(),
                _buildSubjectsTab(),
                _buildSessionsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton(
          backgroundColor: Colors.purpleAccent,
          onPressed: () {
            if (_tabController.index == 0) {
              _showAddAssignmentDialog();
            } else if (_tabController.index == 1) {
              _showAddSubjectDialog();
            } else {
              _tabController.animateTo(0);
              _showAddAssignmentDialog();
            }
          },
          child: const Icon(LucideIcons.plus, color: Colors.white),
        ),
      ),
    );
  }

  // --- ASSIGNMENTS TAB ---
  Widget _buildAssignmentsTab() {
    final assignmentsState = ref.watch(assignmentsProvider);

    return assignmentsState.when(
      data: (assignments) {
        if (assignments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.fileText, size: 48, color: Colors.white24),
                const SizedBox(height: 16),
                const Text('No assignments yet', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Tap + or ask VAJRA to create one', style: TextStyle(color: Colors.white38, fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final a = assignments[index];
            final isCompleted = a.status == 'COMPLETED';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141418),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCompleted ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => ref.read(assignmentsProvider.notifier).toggleAssignment(a.id),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? Colors.greenAccent : Colors.transparent,
                        border: Border.all(
                          color: isCompleted ? Colors.greenAccent : Colors.white38,
                          width: 2,
                        ),
                      ),
                      child: isCompleted ? const Icon(Icons.check, size: 18, color: Colors.black) : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purpleAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                a.subjectName,
                                style: const TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (a.priority == 'high')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'HIGH',
                                  style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          a.title,
                          style: TextStyle(
                            color: isCompleted ? Colors.white54 : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (a.dueDate != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(LucideIcons.calendar, size: 12, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('EEE, MMM d').format(a.dueDate!),
                                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, color: Colors.white24, size: 18),
                    onPressed: () => ref.read(assignmentsProvider.notifier).deleteAssignment(a.id),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.cloudOff, size: 40, color: Colors.white24),
            const SizedBox(height: 12),
            const Text('Operating Offline', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Your assignments are saved locally.', style: TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F1F28),
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white10),
              ),
              onPressed: () => ref.read(assignmentsProvider.notifier).loadAssignments(),
              icon: const Icon(LucideIcons.refreshCw, size: 14),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // --- SUBJECTS TAB ---
  Widget _buildSubjectsTab() {
    final subjectsState = ref.watch(subjectsProvider);

    return subjectsState.when(
      data: (subjects) {
        if (subjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.bookOpen, size: 48, color: Colors.white24),
                const SizedBox(height: 16),
                const Text('No subjects added', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Tap + to create your subjects', style: TextStyle(color: Colors.white38, fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final s = subjects[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141418),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.bookOpen, color: Colors.purpleAccent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (s.description != null && s.description!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(s.description!, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                        ],
                        if (s.examDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Exam: ${DateFormat('MMM d, yyyy').format(s.examDate!)}',
                            style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, color: Colors.white24, size: 18),
                    onPressed: () => ref.read(subjectsProvider.notifier).deleteSubject(s.id),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.cloudOff, size: 40, color: Colors.white24),
            const SizedBox(height: 12),
            const Text('Operating Offline', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Your subjects are saved locally.', style: TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F1F28),
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white10),
              ),
              onPressed: () => ref.read(subjectsProvider.notifier).loadSubjects(),
              icon: const Icon(LucideIcons.refreshCw, size: 14),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // --- SESSIONS TAB ---
  Widget _buildSessionsTab() {
    final studyState = ref.watch(studyProvider);

    return studyState.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return const Center(child: Text('No upcoming study sessions', style: TextStyle(color: Colors.white54)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final s = sessions[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141418),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.clock, color: Colors.blueAccent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.subject, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(s.topic, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('${s.durationMinutes} mins', style: const TextStyle(color: Colors.blueAccent, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(DateFormat('EEE, MMM d').format(s.scheduledTime), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.cloudOff, size: 40, color: Colors.white24),
            const SizedBox(height: 12),
            const Text('Operating Offline', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Your study sessions are saved locally.', style: TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F1F28),
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white10),
              ),
              onPressed: () => ref.refresh(studyProvider),
              icon: const Icon(LucideIcons.refreshCw, size: 14),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOGS ---
  void _showAddAssignmentDialog() {
    final titleController = TextEditingController();
    final subjectController = TextEditingController();
    DateTime? selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('New Assignment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subjectController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Subject (e.g. Physics)',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedDate != null ? 'Due: ${DateFormat('MMM d').format(selectedDate!)}' : 'No date',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: const Text('Select Date', style: TextStyle(color: Colors.purpleAccent)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  ref.read(assignmentsProvider.notifier).createAssignment(
                    title: titleController.text.trim(),
                    subjectName: subjectController.text.trim().isNotEmpty ? subjectController.text.trim() : 'General',
                    dueDate: selectedDate,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubjectDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New Subject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Subject Name',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                ref.read(subjectsProvider.notifier).createSubject(
                  name: nameController.text.trim(),
                  description: descController.text.trim().isNotEmpty ? descController.text.trim() : null,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add Subject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
