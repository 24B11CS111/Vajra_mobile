import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/profile_provider.dart';
import '../models/companion_profile_model.dart';
import '../../../core/theme/vajra_colors.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(companionProfileProvider);
    final notifier = ref.read(companionProfileProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Companion Profile', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w300, letterSpacing: -1)),
              const SizedBox(height: 12),
              Text(
                'Configure how VAJRA communicates and proactively assists you.',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              const SizedBox(height: 48),
              
              const Text('PROACTIVITY', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              _buildProactivityDropdown(profile.proactivityLevel, notifier),
              const SizedBox(height: 32),
              
              const Text('COMMUNICATION', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              _buildCommunicationDropdown(profile.communicationStyle, notifier),
              const SizedBox(height: 32),
              
              const Text('BOUNDARIES', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              _buildToggleOption(
                title: 'Require Permission',
                subtitle: 'VAJRA will always ask before modifying your planner.',
                value: profile.requirePermissionForPlanner,
                icon: LucideIcons.shieldCheck,
                onChanged: (v) => notifier.togglePermission(v),
              ),
              _buildToggleOption(
                title: 'Memory Transparency',
                subtitle: 'VAJRA will explicitly tell you when it learns a new preference.',
                value: profile.memoryTransparencyEnabled,
                icon: LucideIcons.eye,
                onChanged: (v) => notifier.toggleMemoryTransparency(v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProactivityDropdown(ProactivityLevel current, CompanionProfileNotifier notifier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
            child: const Icon(LucideIcons.activity, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Proactivity Level', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('Determines if VAJRA actively suggests schedule changes.', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<ProactivityLevel>(
              value: current,
              icon: Icon(LucideIcons.chevronDown, color: Colors.grey[600], size: 16),
              dropdownColor: const Color(0xFF181818),
              style: const TextStyle(color: VajraColors.accent, fontSize: 14, fontWeight: FontWeight.w500),
              onChanged: (ProactivityLevel? newValue) {
                if (newValue != null) notifier.updateProactivity(newValue);
              },
              items: ProactivityLevel.values.map((ProactivityLevel value) {
                return DropdownMenuItem<ProactivityLevel>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(value.name.toUpperCase()),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationDropdown(CommunicationStyle current, CompanionProfileNotifier notifier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
            child: const Icon(LucideIcons.messageSquare, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Communication Style', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('Adjust VAJRA\'s conversational tone.', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<CommunicationStyle>(
              value: current,
              icon: Icon(LucideIcons.chevronDown, color: Colors.grey[600], size: 16),
              dropdownColor: const Color(0xFF181818),
              style: const TextStyle(color: VajraColors.accent, fontSize: 14, fontWeight: FontWeight.w500),
              onChanged: (CommunicationStyle? newValue) {
                if (newValue != null) notifier.updateStyle(newValue);
              },
              items: CommunicationStyle.values.map((CommunicationStyle value) {
                return DropdownMenuItem<CommunicationStyle>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(value.name.toUpperCase()),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({required String title, required String subtitle, required bool value, required IconData icon, required ValueChanged<bool> onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 18),
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
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: VajraColors.accent.withValues(alpha: 0.5),
            activeThumbColor: VajraColors.accent,
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[800],
          )
        ],
      ),
    );
  }
}
