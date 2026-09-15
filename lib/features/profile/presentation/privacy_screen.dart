import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/vajra_colors.dart';

final privacyMemoryEnabledProvider = StateProvider<bool>((ref) => true);
final privacyProactiveEnabledProvider = StateProvider<bool>((ref) => true);
final privacyVoiceEnabledProvider = StateProvider<bool>((ref) => true);
final privacyHistoryEnabledProvider = StateProvider<bool>((ref) => true);

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoryEnabled = ref.watch(privacyMemoryEnabledProvider);
    final proactiveEnabled = ref.watch(privacyProactiveEnabledProvider);
    final voiceEnabled = ref.watch(privacyVoiceEnabledProvider);
    final historyEnabled = ref.watch(privacyHistoryEnabledProvider);

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
                'Privacy & Controls',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage how VAJRA 3.0 stores personal memories, triggers proactive suggestions, and accesses device capabilities.',
                style: TextStyle(color: VajraColors.secondaryText, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 28),
              _buildPrivacyCard(
                icon: LucideIcons.brain,
                title: 'Semantic Memory Vault',
                subtitle: 'Allow VAJRA to remember preferences and study habits.',
                value: memoryEnabled,
                onChanged: (val) => ref.read(privacyMemoryEnabledProvider.notifier).state = val,
              ),
              const SizedBox(height: 12),
              _buildPrivacyCard(
                icon: LucideIcons.sparkles,
                title: 'Proactive Assistance',
                subtitle: 'Enable morning briefings and timely study alerts.',
                value: proactiveEnabled,
                onChanged: (val) => ref.read(privacyProactiveEnabledProvider.notifier).state = val,
              ),
              const SizedBox(height: 12),
              _buildPrivacyCard(
                icon: LucideIcons.mic,
                title: 'Voice Assistant',
                subtitle: 'Allow microphone access for conversational voice mode.',
                value: voiceEnabled,
                onChanged: (val) => ref.read(privacyVoiceEnabledProvider.notifier).state = val,
              ),
              const SizedBox(height: 12),
              _buildPrivacyCard(
                icon: LucideIcons.history,
                title: 'Activity Logging',
                subtitle: 'Record action history for undo and diagnostics.',
                value: historyEnabled,
                onChanged: (val) => ref.read(privacyHistoryEnabledProvider.notifier).state = val,
              ),
              const SizedBox(height: 32),
              Center(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18),
                  label: const Text('Clear All Stored Memories', style: TextStyle(color: Colors.redAccent)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All semantic memories cleared.')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.3)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.white24,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
