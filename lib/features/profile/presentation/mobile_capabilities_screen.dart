import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/assistant/device_control_service.dart';
import '../../../core/assistant/mobile_app_launch_engine.dart';
import '../../../core/assistant/mobile_app_registry.dart';
import '../../../core/theme/vajra_colors.dart';

class MobileCapabilitiesScreen extends ConsumerStatefulWidget {
  const MobileCapabilitiesScreen({super.key});

  @override
  ConsumerState<MobileCapabilitiesScreen> createState() => _MobileCapabilitiesScreenState();
}

class _MobileCapabilitiesScreenState extends ConsumerState<MobileCapabilitiesScreen> {
  Map<String, bool> _installationStatus = {};
  bool _isLoading = true;
  String? _lastTestResult;

  @override
  void initState() {
    super.initState();
    _checkInstalledApps();
  }

  Future<void> _checkInstalledApps() async {
    setState(() => _isLoading = true);
    final deviceService = ref.read(deviceControlServiceProvider);
    final packages = MobileAppRegistry.approvedApps.map((a) => a.defaultPackage).toList();

    try {
      final statusMap = await deviceService.checkInstalledPackages(packages);
      if (mounted) {
        setState(() {
          _installationStatus = statusMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _testLaunch(String appId) async {
    final launchEngine = ref.read(mobileAppLaunchEngineProvider);
    final res = await launchEngine.launchApp(appId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: res.success ? const Color(0xFF10B981) : Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {
        _lastTestResult = '${res.appName ?? appId}: ${res.message}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _checkInstalledApps,
          color: const Color(0xFF10B981),
          backgroundColor: const Color(0xFF121212),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (Navigator.of(context).canPop())
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
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
                const Text(
                  'Phone Capabilities',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hardware-verified application registry, deep action intents, and native Android execution pipeline.',
                  style: TextStyle(color: VajraColors.secondaryText, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // Platform Channel Telemetry Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF242424)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(LucideIcons.smartphone, color: Color(0xFF10B981), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Native Android Platform Engine',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                                Text(
                                  'Channel: com.vajra.app/device_control',
                                  style: TextStyle(color: VajraColors.secondaryText, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFF242424), height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem('Approved Apps', '${MobileAppRegistry.approvedApps.length}'),
                          _buildStatItem('Safety Tiers', '3 Tiers'),
                          _buildStatItem('Deep Actions', '12 Types'),
                        ],
                      ),
                      if (_lastTestResult != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.terminal, color: Color(0xFF10B981), size: 14),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _lastTestResult!,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'REGISTERED APPLICATIONS',
                      style: TextStyle(
                        color: VajraColors.secondaryText,
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // List of registered apps
                ...MobileAppRegistry.approvedApps.map((app) {
                  final isInstalled = _installationStatus[app.defaultPackage] ?? true;
                  return _buildAppCard(app, isInstalled);
                }),

                const SizedBox(height: 16),

                // Safety Policy Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF242424)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(LucideIcons.shieldCheck, color: Colors.blueAccent, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Universal Action Safety Policy',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSafetyRow('Tier 1: Low Risk', 'Direct app launching, searches, navigation (Immediate execution)', const Color(0xFF10B981)),
                      const SizedBox(height: 8),
                      _buildSafetyRow('Tier 2: Confirmation Required', 'Outbound telephony calls, sending SMS/messages', Colors.amberAccent),
                      const SizedBox(height: 8),
                      _buildSafetyRow('Tier 3: Blocked', 'Arbitrary package execution, shell commands, mass automation', Colors.redAccent),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: VajraColors.secondaryText, fontSize: 12)),
      ],
    );
  }

  Widget _buildSafetyRow(String title, String desc, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 5, right: 10),
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
              Text(desc, style: const TextStyle(color: VajraColors.secondaryText, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppCard(AppDefinition app, bool isInstalled) {
    IconData iconData = LucideIcons.appWindow;
    switch (app.id) {
      case 'chrome':
        iconData = LucideIcons.globe;
        break;
      case 'youtube':
        iconData = LucideIcons.playSquare;
        break;
      case 'instagram':
        iconData = LucideIcons.camera;
        break;
      case 'whatsapp':
        iconData = LucideIcons.messageCircle;
        break;
      case 'maps':
        iconData = LucideIcons.mapPin;
        break;
      case 'settings':
        iconData = LucideIcons.settings;
        break;
      case 'dialer':
        iconData = LucideIcons.phone;
        break;
      case 'messages':
        iconData = LucideIcons.messageSquare;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF242424)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          app.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isInstalled
                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                : Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isInstalled ? 'INSTALLED' : 'UNVERIFIED',
                            style: TextStyle(
                              color: isInstalled ? const Color(0xFF10B981) : Colors.amber,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      app.defaultPackage,
                      style: const TextStyle(color: VajraColors.secondaryText, fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _testLaunch(app.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E1E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFF333333)),
                  ),
                ),
                child: const Text('Open', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: app.supportedActions.map((action) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF2B2B2B)),
                ),
                child: Text(
                  action,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
