import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/notification_provider.dart';
import '../../../core/theme/vajra_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (Navigator.of(context).canPop())
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
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
                  const Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w300, letterSpacing: -1)),
                ],
              ),
            ),
            Expanded(
              child: notificationState.when(
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return const Center(
                      child: Text('No new notifications.', style: TextStyle(color: VajraColors.secondaryText)),
                    );
                  }
                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return GestureDetector(
                        onTap: () {
                          if (!notification.isRead) {
                            ref.read(notificationProvider.notifier).markAsRead(notification.id);
                          }
                        },
                        child: _buildNotificationCard(
                          notification.message,
                          timeago.format(notification.timestamp),
                          notification.isRead,
                        ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.1, end: 0),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: VajraColors.accent)),
                error: (error, _) => Center(child: Text('Failed to load notifications: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(String message, String time, bool isRead) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isRead ? const Color(0xFF111111) : const Color(0xFF181818),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isRead ? Colors.white.withValues(alpha: 0.05) : VajraColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(LucideIcons.bellRing, color: isRead ? VajraColors.secondaryText : VajraColors.accent, size: 16),
              Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: isRead ? Colors.grey[400] : Colors.white, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}

