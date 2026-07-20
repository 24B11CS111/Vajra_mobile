import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/vajra_avatar.dart';
import '../../core/theme/vajra_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Artificial delay to show splash animations
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      context.go('/onboarding');
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
