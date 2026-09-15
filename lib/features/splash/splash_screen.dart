import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/widgets/vajra_avatar.dart';
import '../../core/theme/vajra_colors.dart';
import '../authentication/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      final authState = ref.read(authProvider);
      final prefs = await SharedPreferences.getInstance();
      if (authState == AuthState.authenticated) {
        final setupCompleted = prefs.getBool('vajra_permissions_setup_completed') ?? false;
        if (mounted) {
          if (setupCompleted) {
            context.go('/home');
          } else {
            context.go('/setup');
          }
        }
      } else {
        final onboardingCompleted = prefs.getBool('vajra_onboarding_completed') ?? false;
        if (mounted) {
          if (!onboardingCompleted) {
            context.go('/onboarding');
          } else {
            context.go('/auth');
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VajraColors.primaryBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const VajraAvatar(size: 160, state: AvatarState.idle)
                .animate()
                .fadeIn(duration: 1.seconds)
                .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack, duration: 1.5.seconds),
            const SizedBox(height: 48),
            Text(
              'VAJRA',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    letterSpacing: 8.0,
                    fontWeight: FontWeight.w300,
                  ),
            ).animate().fadeIn(delay: 500.ms, duration: 800.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 16),
            Text(
              'Always With You.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: VajraColors.secondaryText,
                    letterSpacing: 2.0,
                  ),
            ).animate().fadeIn(delay: 1.seconds, duration: 800.ms),
          ],
        ),
      ),
    );
  }
}
