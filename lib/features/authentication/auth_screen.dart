import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/vajra_colors.dart';
import '../../shared/widgets/vajra_button.dart';
import '../../shared/widgets/vajra_card.dart';
import '../../shared/widgets/vajra_input.dart';
import 'providers/auth_provider.dart';
import 'services/auth_repository.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignUp = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }

    if (_isSignUp) {
      ref.read(authProvider.notifier).signup(email, password, name.isNotEmpty ? name : null);
    } else {
      ref.read(authProvider.notifier).login(email, password);
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your registered email address to receive password reset instructions.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Password reset link sent to ${resetEmailController.text.trim()}')),
              );
            },
            child: const Text('Send Reset Link', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) async {
      if (next == AuthState.authenticated) {
        final prefs = await SharedPreferences.getInstance();
        final setupCompleted = prefs.getBool('vajra_permissions_setup_completed') ?? false;
        if (context.mounted) {
          if (setupCompleted) {
            context.go('/home');
          } else {
            context.go('/setup');
          }
        }
      } else if (next == AuthState.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication failed. Please check your inputs.')),
        );
      }
    });

    final isLoading = authState == AuthState.loading;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 36),

              // Title
              Text(
                _isSignUp ? 'Create Account.' : 'Sign In.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ).animate().fadeIn().slideX(begin: 0.1, end: 0),
              const SizedBox(height: 6),
              Text(
                _isSignUp ? 'Join VAJRA as your personal AI companion.' : 'Welcome back to your personal companion.',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.1, end: 0),
              const SizedBox(height: 24),

              // Toggle Tab (Sign In / Sign Up)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF141418),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isSignUp = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isSignUp ? Colors.purpleAccent : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: !_isSignUp ? Colors.white : Colors.white54,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isSignUp = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isSignUp ? Colors.purpleAccent : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: _isSignUp ? Colors.white : Colors.white54,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Auth Card
              VajraCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSignUp) ...[
                      VajraInput(
                        hintText: 'Full Name',
                        controller: _nameController,
                        prefixIcon: LucideIcons.user,
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 16),
                    ],
                    VajraInput(
                      hintText: 'Email address',
                      controller: _emailController,
                      prefixIcon: LucideIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    VajraInput(
                      hintText: 'Password',
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      prefixIcon: LucideIcons.lock,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                          color: VajraColors.secondaryText,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    if (!_isSignUp) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: Colors.purpleAccent, fontSize: 12),
                          ),
                        ),
                      ),
                    ] else
                      const SizedBox(height: 20),
                    VajraButton(
                      text: isLoading
                          ? (_isSignUp ? 'Creating Account...' : 'Signing In...')
                          : (_isSignUp ? 'Create Account' : 'Sign In'),
                      icon: _isSignUp ? LucideIcons.userPlus : LucideIcons.logIn,
                      type: VajraButtonType.primary,
                      isLoading: isLoading,
                      onPressed: _handleSubmit,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'OR',
                      style: TextStyle(
                        color: VajraColors.secondaryText,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    VajraButton(
                      text: 'Continue with Google',
                      icon: LucideIcons.globe,
                      type: VajraButtonType.secondary,
                      isLoading: isLoading,
                      onPressed: () {
                        ref.read(authProvider.notifier).socialLogin(AuthProviderType.google);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: isLoading ? null : () => ref.read(authProvider.notifier).guestLogin(),
                      child: const Text(
                        'Continue as Guest',
                        style: TextStyle(color: VajraColors.secondaryText, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
