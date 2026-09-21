import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/profile_provider.dart';
import '../models/companion_profile_model.dart';
import '../models/user_profile_model.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../../core/theme/vajra_colors.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _showEditProfileDialog(UserProfileModel user) {
    final nameController = TextEditingController(text: user.name);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Display Name', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose how VAJRA should address you.', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF222222),
                hintText: 'Your name',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: VajraColors.accent, width: 1.5)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: VajraColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                Navigator.of(dialogContext).pop();
                final success = await ref.read(profileProvider.notifier).updateDisplayName(newName);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Profile updated successfully' : 'Failed to update profile'),
                      backgroundColor: success ? const Color(0xFF1E3A8A) : Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(LucideIcons.logOut, color: Colors.redAccent, size: 20),
            SizedBox(width: 10),
            Text('Log Out', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of VAJRA? You will need to sign in again to access your companion.',
          style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(profileProvider);
    final companionProfile = ref.watch(companionProfileProvider);
    final companionNotifier = ref.read(companionProfileProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: RefreshIndicator(
          color: VajraColors.accent,
          backgroundColor: const Color(0xFF161616),
          onRefresh: () async {
            await ref.read(profileProvider.notifier).refresh();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Bar Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Profile & Settings', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w400, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                          SizedBox(height: 2),
                          Text('VAJRA Personal Assistant 5.0', style: TextStyle(color: Colors.grey, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: VajraColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: VajraColors.accent.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.sparkles, color: VajraColors.accent, size: 11),
                              SizedBox(width: 4),
                              Text('ACTIVE', style: TextStyle(color: VajraColors.accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(LucideIcons.settings, color: Colors.white70, size: 20),
                          tooltip: 'Full Settings',
                          onPressed: () => context.push('/settings'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // User Identity Card
                userProfileAsync.when(
                  data: (user) => _buildUserIdentityCard(user),
                  loading: () => _buildUserIdentityLoading(),
                  error: (err, _) => _buildUserIdentityError(),
                ),
                const SizedBox(height: 28),

                // Section: Personalization & Intelligence
                _buildSectionHeader('PERSONALIZATION', LucideIcons.sliders),
                const SizedBox(height: 12),
                _buildProactivitySelector(companionProfile.proactivityLevel, companionNotifier),
                const SizedBox(height: 12),
                _buildCommunicationStyleSelector(companionProfile.communicationStyle, companionNotifier),
                const SizedBox(height: 28),

                // Section: Privacy & Autonomy Controls
                _buildSectionHeader('AUTONOMY & PRIVACY', LucideIcons.shield),
                const SizedBox(height: 12),
                _buildToggleCard(
                  title: 'Planner Permission Gate',
                  subtitle: 'Require manual confirmation before modifying your schedule or tasks.',
                  icon: LucideIcons.shieldCheck,
                  value: companionProfile.requirePermissionForPlanner,
                  onChanged: (val) => companionNotifier.togglePermission(val),
                ),
                const SizedBox(height: 12),
                _buildToggleCard(
                  title: 'Memory Transparency',
                  subtitle: 'Notify you explicitly whenever VAJRA extracts and stores a new preference.',
                  icon: LucideIcons.eye,
                  value: companionProfile.memoryTransparencyEnabled,
                  onChanged: (val) => companionNotifier.toggleMemoryTransparency(val),
                ),
                const SizedBox(height: 28),

                // Section: Vault & System Navigation
                _buildSectionHeader('DATA & SYSTEM', LucideIcons.database),
                const SizedBox(height: 12),
                _buildNavigationCard(
                  icon: LucideIcons.brain,
                  title: 'Memory Vault',
                  subtitle: 'View, search, and manage your semantic memories.',
                  onTap: () => context.push('/memory'),
                ),
                const SizedBox(height: 12),
                _buildNavigationCard(
                  icon: LucideIcons.shieldAlert,
                  title: 'Privacy Controls',
                  subtitle: 'Granular permissions for voice, memory, and proactivity.',
                  onTap: () => context.push('/privacy'),
                ),
                const SizedBox(height: 12),
                _buildNavigationCard(
                  icon: LucideIcons.activity,
                  title: 'Activity Log',
                  subtitle: 'Inspect audit trail of AI agent actions and tools.',
                  onTap: () => context.push('/activity-log'),
                ),
                const SizedBox(height: 12),
                _buildNavigationCard(
                  icon: LucideIcons.cpu,
                  title: 'Diagnostics & Health',
                  subtitle: 'Check backend connectivity, DB, and SSE streaming status.',
                  onTap: () => context.push('/diagnostics'),
                ),
                const SizedBox(height: 12),
                _buildNavigationCard(
                  icon: LucideIcons.smartphone,
                  title: 'Phone Capabilities',
                  subtitle: 'Inspect installed app verification, deep actions, & intent routing.',
                  onTap: () => context.push('/capabilities'),
                ),
                const SizedBox(height: 32),

                // Section: Account & Logout
                _buildSectionHeader('ACCOUNT & SESSION', LucideIcons.user),
                const SizedBox(height: 12),
                Material(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _showLogoutConfirmation,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.logOut, color: Colors.redAccent, size: 18),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Log Out', style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.w600)),
                                SizedBox(height: 2),
                                Text('End active session on this device', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[500], size: 14),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildUserIdentityCard(UserProfileModel user) {
    final initials = user.name.isNotEmpty
        ? user.name.trim().split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase()
        : 'V';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: VajraColors.accent.withValues(alpha: 0.2),
            child: Text(
              initials,
              style: const TextStyle(
                color: VajraColors.accent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showEditProfileDialog(user),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.pencil, color: Colors.grey, size: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserIdentityLoading() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFF1E1E1E),
            child: CircularProgressIndicator(strokeWidth: 2, color: VajraColors.accent),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Loading profile...', style: TextStyle(color: Colors.white, fontSize: 16)),
              SizedBox(height: 4),
              Text('Connecting to server...', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserIdentityError() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VajraColors.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: VajraColors.accent.withValues(alpha: 0.1),
                child: const Icon(LucideIcons.user, color: VajraColors.accent, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Local Guest Session', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Sign in to sync memories & AI profile', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: VajraColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(LucideIcons.logIn, size: 16),
              label: const Text('Sign In to VAJRA', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              onPressed: () => context.push('/auth'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProactivitySelector(ProactivityLevel current, CompanionProfileNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(LucideIcons.zap, color: VajraColors.accent, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text('Proactivity', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<ProactivityLevel>(
                  value: current,
                  dropdownColor: const Color(0xFF1E1E1E),
                  icon: const Icon(LucideIcons.chevronDown, color: Colors.grey, size: 16),
                  style: const TextStyle(color: VajraColors.accent, fontSize: 12, fontWeight: FontWeight.w600),
                  items: ProactivityLevel.values.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (newLevel) {
                    if (newLevel != null) notifier.updateProactivity(newLevel);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            current == ProactivityLevel.proactive
                ? 'VAJRA automatically proposes schedule adjustments and reminders.'
                : current == ProactivityLevel.balanced
                    ? 'VAJRA provides morning/evening briefings and occasional recommendations.'
                    : 'VAJRA only responds when explicitly addressed.',
            style: TextStyle(color: Colors.grey[400], fontSize: 12, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationStyleSelector(CommunicationStyle current, CompanionProfileNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(LucideIcons.messageSquare, color: VajraColors.accent, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text('AI Tone', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<CommunicationStyle>(
                  value: current,
                  dropdownColor: const Color(0xFF1E1E1E),
                  icon: const Icon(LucideIcons.chevronDown, color: Colors.grey, size: 16),
                  style: const TextStyle(color: VajraColors.accent, fontSize: 12, fontWeight: FontWeight.w600),
                  items: CommunicationStyle.values.map((style) {
                    return DropdownMenuItem(
                      value: style,
                      child: Text(style.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (newStyle) {
                    if (newStyle != null) notifier.updateStyle(newStyle);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            current == CommunicationStyle.direct
                ? 'Direct, succinct bullet points and minimal conversation.'
                : current == CommunicationStyle.reflective
                    ? 'In-depth explanations with complete contextual rationale.'
                    : current == CommunicationStyle.encouraging
                        ? 'Encouraging, supportive tone focused on habit building.'
                        : 'Academic rigor with detailed foundational references.',
            style: TextStyle(color: Colors.grey[400], fontSize: 12, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 12, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeTrackColor: VajraColors.accent.withValues(alpha: 0.5),
            activeThumbColor: VajraColors.accent,
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[800],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}
