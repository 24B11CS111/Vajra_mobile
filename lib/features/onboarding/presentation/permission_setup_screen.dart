import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/integrations/device_permission_service.dart';
import '../../../shared/widgets/vajra_button.dart';
import '../../../shared/widgets/vajra_card.dart';

class PermissionSetupScreen extends ConsumerStatefulWidget {
  const PermissionSetupScreen({super.key});

  @override
  ConsumerState<PermissionSetupScreen> createState() => _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends ConsumerState<PermissionSetupScreen> {
  final Map<DevicePermissionType, bool> _connectedStatus = {
    DevicePermissionType.calendar: false,
    DevicePermissionType.notifications: false,
    DevicePermissionType.microphone: false,
    DevicePermissionType.location: false,
  };

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkInitialPermissions();
  }

  Future<void> _checkInitialPermissions() async {
    final service = ref.read(devicePermissionServiceProvider);
    for (final type in _connectedStatus.keys) {
      final status = await service.checkStatus(type);
      if (mounted) {
        setState(() {
          _connectedStatus[type] = (status == DevicePermissionState.granted);
        });
      }
    }
  }

  Future<void> _requestPermission(DevicePermissionType type) async {
    final service = ref.read(devicePermissionServiceProvider);
    final status = await service.request(type);
    if (mounted) {
      setState(() {
        _connectedStatus[type] = (status == DevicePermissionState.granted);
      });
      if (status == DevicePermissionState.permanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Permission was permanently denied. You can enable it in Settings.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => service.openSettings(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _completeSetup() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vajra_permissions_setup_completed', true);
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Subtitle Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'DEVICE INTEGRATION',
                  style: TextStyle(
                    color: Colors.purpleAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ).animate().fadeIn().slideX(begin: -0.1, end: 0),
              const SizedBox(height: 14),

              // Headline
              const Text(
                'CONNECT VAJRA TO YOUR WORLD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05, end: 0),
              const SizedBox(height: 10),

              const Text(
                'Empower VAJRA with context to assist you proactively. All permissions are optional and can be modified anytime in Settings.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                  height: 1.4,
                ),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 28),

              // Integration Cards
              _buildIntegrationTile(
                type: DevicePermissionType.calendar,
                icon: LucideIcons.calendar,
                title: 'Calendar',
                description: 'Let VAJRA understand your schedule.',
                delayMs: 200,
              ),
              const SizedBox(height: 14),

              _buildIntegrationTile(
                type: DevicePermissionType.notifications,
                icon: LucideIcons.bell,
                title: 'Notifications',
                description: 'Let VAJRA remind you when it matters.',
                delayMs: 250,
              ),
              const SizedBox(height: 14),

              _buildIntegrationTile(
                type: DevicePermissionType.microphone,
                icon: LucideIcons.mic,
                title: 'Voice',
                description: 'Talk naturally with VAJRA.',
                delayMs: 300,
              ),
              const SizedBox(height: 14),

              _buildIntegrationTile(
                type: DevicePermissionType.location,
                icon: LucideIcons.mapPin,
                title: 'Location',
                description: 'Enable location-aware assistance when you need it.',
                delayMs: 350,
              ),
              const SizedBox(height: 36),

              // Action Buttons
              VajraButton(
                text: 'Continue to VAJRA',
                icon: LucideIcons.arrowRight,
                type: VajraButtonType.primary,
                isLoading: _isLoading,
                onPressed: _completeSetup,
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 12),

              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _completeSetup,
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 450.ms),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntegrationTile({
    required DevicePermissionType type,
    required IconData icon,
    required String title,
    required String description,
    required int delayMs,
  }) {
    final isConnected = _connectedStatus[type] ?? false;

    return VajraCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isConnected
                  ? Colors.greenAccent.withValues(alpha: 0.15)
                  : const Color(0xFF18181E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isConnected ? Colors.greenAccent.withValues(alpha: 0.4) : Colors.white10,
              ),
            ),
            child: Icon(
              icon,
              color: isConnected ? Colors.greenAccent : Colors.purpleAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isConnected ? null : () => _requestPermission(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isConnected
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.purpleAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isConnected ? Colors.greenAccent : Colors.purpleAccent,
                  width: 1.2,
                ),
              ),
              child: Text(
                isConnected ? 'Connected ✓' : 'Connect',
                style: TextStyle(
                  color: isConnected ? Colors.greenAccent : Colors.purpleAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delayMs)).slideY(begin: 0.05, end: 0);
  }
}
