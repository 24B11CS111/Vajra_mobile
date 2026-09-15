import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/orchestrator/models/agent_models.dart';

/// Compact execution card showing real-time agent multi-step progress.
class ActionPlanCard extends StatelessWidget {
  final AgentPlan plan;

  const ActionPlanCard({
    super.key,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              const Text(
                'VAJRA 3.0 AGENT',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (plan.isCompleted)
                const Row(
                  children: [
                    Icon(LucideIcons.checkCheck, color: Color(0xFF10B981), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'COMPLETE',
                      style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              else
                const Row(
                  children: [
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'EXECUTING',
                      style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            plan.goal,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),
          ...plan.steps.map((step) => _buildStepRow(step)),
        ],
      ),
    );
  }

  Widget _buildStepRow(AgentStep step) {
    Widget icon;
    TextStyle textStyle;

    switch (step.status) {
      case StepStatus.completed:
        icon = const Icon(LucideIcons.check, color: Color(0xFF10B981), size: 14);
        textStyle = const TextStyle(color: Colors.white70, fontSize: 12);
        break;
      case StepStatus.inProgress:
        icon = const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        );
        textStyle = const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600);
        break;
      case StepStatus.failed:
        icon = const Icon(LucideIcons.x, color: Colors.redAccent, size: 14);
        textStyle = const TextStyle(color: Colors.redAccent, fontSize: 12);
        break;
      case StepStatus.pending:
      case StepStatus.skipped:
        icon = const Icon(LucideIcons.circle, color: Colors.white24, size: 12);
        textStyle = const TextStyle(color: Colors.white38, fontSize: 12);
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 18, child: Center(child: icon)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              step.description,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
