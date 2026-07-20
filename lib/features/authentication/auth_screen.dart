import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/vajra_colors.dart';
import '../../shared/widgets/vajra_button.dart';
import '../../shared/widgets/vajra_card.dart';
import 'providers/auth_provider.dart';
import 'services/auth_repository.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next == AuthState.authenticated) {
        context.go('/home');
      } else if (next == AuthState.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication failed')),
        );
      }
    });

    final isLoading = authState == AuthState.loading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 64),
              Text(
                'Sign In.',
                style: Theme.of(context).textTheme.displayLarge,
              ).animate().fadeIn().slideX(begin: 0.1, end: 0),
              const SizedBox(height: 16),
              Text(
                'Welcome back to your companion.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: VajraColors.secondaryText,
                    ),
              ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.1, end: 0),
              const Spacer(),
              VajraCard(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VajraButton(
                      text: isLoading ? 'Loading...' : 'Continue with Google',
                      icon: LucideIcons.mail,
                      type: VajraButtonType.secondary,
                      isLoading: isLoading,
                      onPressed: () { ref.read(authProvider.notifier).socialLogin(AuthProviderType.google); },
                    ),
                    const SizedBox(height: 16),
                    VajraButton(
                      text: isLoading ? 'Loading...' : 'Continue with Apple',
                      icon: LucideIcons.apple,
                      type: VajraButtonType.secondary,
                      isLoading: isLoading,
                      onPressed: () { ref.read(authProvider.notifier).socialLogin(AuthProviderType.apple); },
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'OR',
                      style: TextStyle(
                        color: VajraColors.secondaryText,
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    VajraButton(
                      text: isLoading ? 'Loading...' : 'Continue with Email',
                      icon: LucideIcons.atSign,
                      type: VajraButtonType.primary,
                      isLoading: isLoading,
                      onPressed: () { ref.read(authProvider.notifier).login('email', 'password'); }, // Will implement actual form later
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () { ref.read(authProvider.notifier).guestLogin(); },
                      child: const Text(
                        'Continue as Guest',
                        style: TextStyle(
                          color: VajraColors.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                    )
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }
}
