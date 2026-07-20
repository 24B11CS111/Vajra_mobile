import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/planner_provider.dart';
import 'widgets/planner_task_card.dart';

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plannerState = ref.watch(plannerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('Daily Planner', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w300, letterSpacing: -1)),
            ),
            Expanded(
              child: plannerState.when(
                data: (tasks) {
                  return ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: tasks.length,
                    onReorderItem: (oldIndex, newIndex) {
                      ref.read(plannerProvider.notifier).reorderTasks(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      return Container(
                        key: ValueKey(tasks[index].id),
                        child: PlannerTaskCard(task: tasks[index]),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                error: (e, _) => Center(child: Text(e.toString(), style: const TextStyle(color: Colors.red))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
