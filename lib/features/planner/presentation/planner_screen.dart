import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/vajra_offline_banner.dart';
import '../models/planner_model.dart';
import '../models/calendar_event_model.dart';
import '../providers/planner_provider.dart';
import 'widgets/planner_task_card.dart';

enum CalendarViewType { day, week, month }

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  CalendarViewType _selectedView = CalendarViewType.week;
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(plannerProvider);
    final eventsState = ref.watch(calendarEventsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0C),
        elevation: 0,
        title: const Text(
          'Calendar & Planner',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, color: Colors.purpleAccent, size: 24),
            onPressed: _showAddEventDialog,
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Colors.white54, size: 20),
            onPressed: () {
              ref.read(plannerProvider.notifier).loadTasks();
              ref.read(calendarEventsProvider.notifier).loadEvents();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const VajraOfflineBanner(),
            // View Mode Selector (Day | Week | Month)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildViewTab('Day', CalendarViewType.day),
                  const SizedBox(width: 8),
                  _buildViewTab('Week', CalendarViewType.week),
                  const SizedBox(width: 8),
                  _buildViewTab('Month', CalendarViewType.month),
                ],
              ),
            ),

            // Interactive Date Bar / Calendar Header
            _buildCalendarHeader(),

            // Filter Chips
            _buildFilterChips(),

            const SizedBox(height: 8),

            // Content Area based on View
            Expanded(
              child: _selectedView == CalendarViewType.month
                  ? _buildMonthGridView(eventsState, tasksState)
                  : _buildTimelineAndTasks(tasksState, eventsState),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton(
          backgroundColor: Colors.purpleAccent,
          onPressed: _showAddEventDialog,
          child: const Icon(LucideIcons.plus, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildViewTab(String label, CalendarViewType type) {
    final isSelected = _selectedView == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedView = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.purpleAccent : const Color(0xFF141418),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? Colors.purpleAccent : Colors.white10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    if (_selectedView == CalendarViewType.week) {
      // 7-day horizontal strip
      final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      return Container(
        height: 75,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: 7,
          itemBuilder: (context, index) {
            final date = startOfWeek.add(Duration(days: index));
            final isSelected = DateUtils.isSameDay(date, _selectedDate);
            final isToday = DateUtils.isSameDay(date, DateTime.now());

            return GestureDetector(
              onTap: () => setState(() => _selectedDate = date),
              child: Container(
                width: 50,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.purpleAccent.withValues(alpha: 0.2) : const Color(0xFF141418),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? Colors.purpleAccent
                        : (isToday ? Colors.blueAccent : Colors.white.withValues(alpha: 0.05)),
                    width: isSelected || isToday ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('E').format(date).substring(0, 1),
                      style: TextStyle(
                        color: isSelected ? Colors.purpleAccent : Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date.day.toString(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMMM yyyy').format(_selectedDate),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.chevronLeft, color: Colors.white70, size: 20),
                  onPressed: () {
                    setState(() {
                      if (_selectedView == CalendarViewType.month) {
                        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
                      } else {
                        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(LucideIcons.chevronRight, color: Colors.white70, size: 20),
                  onPressed: () {
                    setState(() {
                      if (_selectedView == CalendarViewType.month) {
                        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
                      } else {
                        _selectedDate = _selectedDate.add(const Duration(days: 1));
                      }
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Sessions', 'Tasks', 'Deadlines'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12)),
              selected: isSelected,
              backgroundColor: const Color(0xFF141418),
              selectedColor: Colors.purpleAccent.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? Colors.purpleAccent : Colors.white10),
              ),
              onSelected: (_) => setState(() => _selectedFilter = f),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthGridView(
    AsyncValue<List<CalendarEventModel>> eventsState,
    AsyncValue<List<PlannerTask>> tasksState,
  ) {
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_selectedDate.year, _selectedDate.month);
    final startWeekday = firstDayOfMonth.weekday; // 1 = Monday

    final allEvents = eventsState.valueOrNull ?? [];
    final allTasks = tasksState.valueOrNull ?? [];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: 42,
      itemBuilder: (context, index) {
        final dayOffset = index - (startWeekday - 1);
        if (dayOffset < 0 || dayOffset >= daysInMonth) {
          return const SizedBox.shrink();
        }
        final day = dayOffset + 1;
        final cellDate = DateTime(_selectedDate.year, _selectedDate.month, day);
        final isSelected = DateUtils.isSameDay(cellDate, _selectedDate);
        final isToday = DateUtils.isSameDay(cellDate, DateTime.now());

        final hasTasksOnDay = allTasks.any((t) => DateUtils.isSameDay(t.startTime, cellDate));
        final hasEventsOnDay = allEvents.any((e) => DateUtils.isSameDay(e.startTime, cellDate));

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = cellDate;
              _selectedView = CalendarViewType.day;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.purpleAccent.withValues(alpha: 0.3) : const Color(0xFF141418),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? Colors.purpleAccent : (isToday ? Colors.blueAccent : Colors.white.withValues(alpha: 0.05)),
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (hasTasksOnDay || hasEventsOnDay) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hasTasksOnDay)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.purpleAccent),
                        ),
                      if (hasEventsOnDay)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<PlannerTask> _filterTasks(List<PlannerTask> tasks, String filter) {
    switch (filter) {
      case 'Sessions':
        return tasks.where((t) => t.category.toLowerCase().contains('study') || t.category.toLowerCase().contains('session')).toList();
      case 'Tasks':
        return tasks;
      case 'Deadlines':
        return tasks.where((t) => t.category.toLowerCase().contains('deadline') || t.category.toLowerCase().contains('assignment') || t.category.toLowerCase().contains('exam')).toList();
      case 'All':
      default:
        return tasks;
    }
  }

  Widget _buildTimelineAndTasks(
    AsyncValue<List<PlannerTask>> tasksState,
    AsyncValue<List<CalendarEventModel>> eventsState,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Scheduled Events Card
        if (_selectedFilter != 'Tasks')
          eventsState.when(
            data: (events) {
              final dayEvents = events.where((e) => DateUtils.isSameDay(e.startTime, _selectedDate)).toList();
              if (dayEvents.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Scheduled Events', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...dayEvents.map((e) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141418),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.purpleAccent),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(
                                    '${DateFormat('hh:mm a').format(e.startTime)} - ${e.endTime != null ? DateFormat('hh:mm a').format(e.endTime!) : '1 hour'}',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.trash2, color: Colors.white24, size: 16),
                              onPressed: () => ref.read(calendarEventsProvider.notifier).deleteEvent(e.id),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

        // Daily Tasks Header
        if (_selectedFilter != 'Sessions') ...[
          const Text('Daily Action Tasks', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          tasksState.when(
            data: (tasks) {
              // Strictly isolate tasks to the selected date
              final dayTasks = tasks.where((t) => DateUtils.isSameDay(t.startTime, _selectedDate)).toList();
              final filteredTasks = _filterTasks(dayTasks, _selectedFilter);

              if (filteredTasks.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: const Text('No tasks planned for this day.', style: TextStyle(color: Colors.white38)),
                );
              }
              return Column(
                children: filteredTasks.map((t) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: PlannerTaskCard(task: t),
                )).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
          error: (e, _) => Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF141418),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.cloudOff, size: 32, color: Colors.white24),
                const SizedBox(height: 8),
                const Text('Offline Mode', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Showing local cached tasks.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F1F28),
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white10),
                  ),
                  onPressed: () => ref.read(plannerProvider.notifier).loadTasks(),
                  icon: const Icon(LucideIcons.refreshCw, size: 14),
                  label: const Text('Retry Sync'),
                ),
              ],
            ),
          ),
        ),
      ],
    ],
  );
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    String eventType = 'study_session';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('New Event / Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              DropdownButtonFormField<String>(
                initialValue: eventType,
                dropdownColor: const Color(0xFF1C1C22),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Type',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                items: const [
                  DropdownMenuItem(value: 'study_session', child: Text('Study Session')),
                  DropdownMenuItem(value: 'task', child: Text('Task')),
                  DropdownMenuItem(value: 'exam', child: Text('Exam')),
                  DropdownMenuItem(value: 'reminder', child: Text('Reminder')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => eventType = val);
                },
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
                  final title = titleController.text.trim();
                  if (eventType == 'task') {
                    ref.read(plannerProvider.notifier).createTask(
                      title: title,
                      dueDate: _selectedDate,
                    );
                  } else {
                    ref.read(calendarEventsProvider.notifier).createEvent(
                      title: title,
                      eventType: eventType,
                      startTime: _selectedDate,
                    );
                  }
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
}
