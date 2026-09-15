import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../authentication/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../models/companion_profile_model.dart';
import '../../memory/services/memory_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final companionState = ref.watch(companionProfileProvider);
    final user = profileState.valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ACCOUNT SECTION
          _buildSectionHeader('ACCOUNT'),
          _buildCard([
            _buildListTile(
              icon: LucideIcons.user,
              title: 'Email',
              subtitle: user?.email ?? 'student@vajra.ai',
            ),
            _buildDivider(),
            _buildListTile(
              icon: LucideIcons.keyRound,
              title: 'Change Password',
              subtitle: 'Update account security credentials',
              onTap: () => _showChangePasswordDialog(context, ref),
            ),
            _buildDivider(),
            _buildListTile(
              icon: LucideIcons.logOut,
              title: 'Log Out',
              subtitle: 'End active mobile session',
              textColor: Colors.orangeAccent,
              onTap: () {
                ref.read(authProvider.notifier).logout();
                context.go('/auth');
              },
            ),
            _buildDivider(),
            _buildListTile(
              icon: LucideIcons.trash2,
              title: 'Delete Account',
              subtitle: 'Permanently purge all data',
              textColor: Colors.redAccent,
              onTap: () => _showDeleteAccountDialog(context, ref),
            ),
          ]),
          const SizedBox(height: 20),

          // AI COMPANION SECTION
          _buildSectionHeader('AI COMPANION'),
          _buildCard([
            _buildListTile(
              icon: LucideIcons.sparkles,
              title: 'AI Personality Tone',
              subtitle: companionState.communicationStyle.name.toUpperCase(),
              onTap: () => _showTonePicker(context, ref),
            ),
            _buildDivider(),
            _buildListTile(
              icon: LucideIcons.zap,
              title: 'Proactivity Level',
              subtitle: companionState.proactivityLevel.name.toUpperCase(),
              onTap: () => _showProactivityPicker(context, ref),
            ),
          ]),
          const SizedBox(height: 20),

          // PRIVACY & DATA SECTION
          _buildSectionHeader('PRIVACY & DATA'),
          _buildCard([
            _buildListTile(
              icon: LucideIcons.brain,
              title: 'Purge Memory Vault',
              subtitle: 'Remove all extracted long-term memories',
              textColor: Colors.redAccent,
              onTap: () => _showPurgeMemoryDialog(context, ref),
            ),
            _buildDivider(),
            _buildListTile(
              icon: LucideIcons.shieldCheck,
              title: 'Privacy Policy',
              subtitle: 'Review encryption & data isolation',
              onTap: () => context.push('/privacy'),
            ),
          ]),
          const SizedBox(height: 20),

          // ABOUT SECTION
          _buildSectionHeader('ABOUT'),
          _buildCard([
            _buildListTile(
              icon: LucideIcons.info,
              title: 'VAJRA Version',
              subtitle: '5.0.0 Production Release',
            ),
            _buildDivider(),
            _buildListTile(
              icon: LucideIcons.activity,
              title: 'System Diagnostics',
              subtitle: 'Inspect API latency and engine health',
              onTap: () => context.push('/diagnostics'),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.purpleAccent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.white.withValues(alpha: 0.05), height: 1, indent: 56);
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: textColor ?? Colors.white70, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: textColor ?? Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              ),
              if (onTap != null) const Icon(LucideIcons.chevronRight, color: Colors.white38, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _showTonePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select AI Tone', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...CommunicationStyle.values.map((s) => ListTile(
                  title: Text(s.name.toUpperCase(), style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    ref.read(companionProfileProvider.notifier).updateStyle(s);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showProactivityPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select Proactivity Level', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...ProactivityLevel.values.map((l) => ListTile(
                  title: Text(l.name.toUpperCase(), style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    ref.read(companionProfileProvider.notifier).updateProactivity(l);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPass,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Old Password', labelStyle: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPass,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'New Password', labelStyle: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password updated successfully')),
              );
            },
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to permanently delete your account and all associated data? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              context.go('/auth');
            },
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPurgeMemoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Purge Memory Vault', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text(
          'This will delete all long-term memories and facts saved by VAJRA. Proceed?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(memoryLocalDataSourceProvider).clearCache();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Memory vault purged')),
              );
            },
            child: const Text('Purge All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
