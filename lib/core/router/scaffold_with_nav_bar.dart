import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/vajra_colors.dart';
import '../../features/devices/services/device_registry_service.dart';
import '../../features/devices/services/remote_action_receiver_service.dart';

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deviceRegistryServiceProvider).registerCurrentDevice();
      ref.read(remoteActionReceiverServiceProvider).start();
    });
  }

  void _onTap(BuildContext context, int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    return Scaffold(
      extendBody: true, // Allows body to extend behind the navbar
      body: navigationShell,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: VajraColors.glassBorder),
          color: VajraColors.glassBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavBarItem(
                      icon: LucideIcons.layoutDashboard,
                      label: 'Home',
                      isSelected: navigationShell.currentIndex == 0,
                      onTap: () => _onTap(context, 0),
                    ),
                    _NavBarItem(
                      icon: LucideIcons.sparkles,
                      label: 'Companion',
                      isSelected: navigationShell.currentIndex == 1,
                      onTap: () => _onTap(context, 1),
                    ),
                    _NavBarItem(
                      icon: LucideIcons.bookOpen,
                      label: 'Study',
                      isSelected: navigationShell.currentIndex == 2,
                      onTap: () => _onTap(context, 2),
                    ),
                    _NavBarItem(
                      icon: LucideIcons.calendarDays,
                      label: 'Planner',
                      isSelected: navigationShell.currentIndex == 3,
                      onTap: () => _onTap(context, 3),
                    ),
                    _NavBarItem(
                      icon: LucideIcons.user,
                      label: 'Profile',
                      isSelected: navigationShell.currentIndex == 4,
                      onTap: () => _onTap(context, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCirc,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? VajraColors.primaryText.withValues(alpha: 0.1) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? VajraColors.primaryText : VajraColors.secondaryText,
          size: 24,
        ),
      ),
    );
  }
}

