/// Safety level governing application execution.
enum ActionSafetyTier {
  lowRisk,
  confirmationRequired,
  blocked,
}

/// Metadata definition for an approved mobile application.
class AppDefinition {
  final String id;
  final String name;
  final String defaultPackage;
  final List<String> fallbackPackages;
  final List<String> aliases;
  final List<String> supportedActions;
  final ActionSafetyTier defaultSafetyTier;

  const AppDefinition({
    required this.id,
    required this.name,
    required this.defaultPackage,
    this.fallbackPackages = const [],
    required this.aliases,
    required this.supportedActions,
    this.defaultSafetyTier = ActionSafetyTier.lowRisk,
  });

  /// Checks whether an input query matches this application's name or any alias.
  bool matches(String query) {
    final clean = query.trim().toLowerCase();
    if (clean == id.toLowerCase() || clean == name.toLowerCase()) return true;
    for (final alias in aliases) {
      if (clean == alias.toLowerCase()) return true;
    }
    return false;
  }
}

/// Centralized registry of approved applications and safe capabilities.
class MobileAppRegistry {
  static const AppDefinition chrome = AppDefinition(
    id: 'chrome',
    name: 'Google Chrome',
    defaultPackage: 'com.android.chrome',
    fallbackPackages: ['com.google.android.apps.chrome', 'org.chromium.chrome'],
    aliases: ['chrome', 'google chrome', 'browser', 'web browser'],
    supportedActions: ['app.launch', 'browser.search', 'browser.open_url'],
    defaultSafetyTier: ActionSafetyTier.lowRisk,
  );

  static const AppDefinition youtube = AppDefinition(
    id: 'youtube',
    name: 'YouTube',
    defaultPackage: 'com.google.android.youtube',
    aliases: ['youtube', 'yt'],
    supportedActions: ['app.launch', 'youtube.search', 'youtube.open_video', 'youtube.open_channel'],
    defaultSafetyTier: ActionSafetyTier.lowRisk,
  );

  static const AppDefinition instagram = AppDefinition(
    id: 'instagram',
    name: 'Instagram',
    defaultPackage: 'com.instagram.android',
    aliases: ['instagram', 'insta', 'ig'],
    supportedActions: ['app.launch', 'instagram.profile', 'instagram.post', 'instagram.reel', 'instagram.open_url'],
    defaultSafetyTier: ActionSafetyTier.lowRisk,
  );

  static const AppDefinition whatsapp = AppDefinition(
    id: 'whatsapp',
    name: 'WhatsApp',
    defaultPackage: 'com.whatsapp',
    fallbackPackages: ['com.whatsapp.w4b'],
    aliases: ['whatsapp', 'wa', 'whats app'],
    supportedActions: ['app.launch', 'whatsapp.chat', 'whatsapp.prepare_message', 'whatsapp.send'],
    defaultSafetyTier: ActionSafetyTier.confirmationRequired,
  );

  static const AppDefinition maps = AppDefinition(
    id: 'maps',
    name: 'Google Maps',
    defaultPackage: 'com.google.android.apps.maps',
    aliases: ['maps', 'google maps', 'navigation', 'gps'],
    supportedActions: ['app.launch', 'maps.search', 'maps.directions', 'maps.navigate'],
    defaultSafetyTier: ActionSafetyTier.lowRisk,
  );

  static const AppDefinition settings = AppDefinition(
    id: 'settings',
    name: 'Settings',
    defaultPackage: 'com.android.settings',
    aliases: ['settings', 'system settings', 'phone settings'],
    supportedActions: [
      'app.launch',
      'settings.main',
      'settings.wifi',
      'settings.bluetooth',
      'settings.sound',
      'settings.display',
      'settings.battery',
      'settings.notifications',
      'settings.app',
      'settings.vajra',
    ],
    defaultSafetyTier: ActionSafetyTier.lowRisk,
  );

  static const AppDefinition phone = AppDefinition(
    id: 'phone',
    name: 'Phone',
    defaultPackage: 'com.google.android.dialer',
    fallbackPackages: ['com.android.dialer', 'com.samsung.android.dialer'],
    aliases: ['phone', 'dialer', 'call', 'telephone'],
    supportedActions: ['app.launch', 'phone.dial', 'phone.prepare_call', 'phone.execute_call'],
    defaultSafetyTier: ActionSafetyTier.confirmationRequired,
  );

  static const AppDefinition messages = AppDefinition(
    id: 'messages',
    name: 'Messages',
    defaultPackage: 'com.google.android.apps.messaging',
    fallbackPackages: ['com.android.mms', 'com.samsung.android.messaging'],
    aliases: ['messages', 'messaging', 'sms', 'text messages'],
    supportedActions: ['app.launch', 'messages.prepare_sms', 'messages.send_sms'],
    defaultSafetyTier: ActionSafetyTier.confirmationRequired,
  );

  /// All officially supported applications in the VAJRA mobile ecosystem.
  static const List<AppDefinition> allApps = [
    chrome,
    youtube,
    instagram,
    whatsapp,
    maps,
    settings,
    phone,
    messages,
  ];

  static List<AppDefinition> get approvedApps => allApps;

  /// Resolves an input application name or alias to its formal AppDefinition.
  static AppDefinition? resolveApp(String query) {
    final clean = query.trim().toLowerCase();
    for (final app in allApps) {
      if (app.matches(clean)) return app;
    }
    return null;
  }

  /// Resolves an app definition by its package name.
  static AppDefinition? resolveByPackage(String packageName) {
    final clean = packageName.trim().toLowerCase();
    for (final app in allApps) {
      if (app.defaultPackage.toLowerCase() == clean) return app;
      for (final fallback in app.fallbackPackages) {
        if (fallback.toLowerCase() == clean) return app;
      }
    }
    return null;
  }

  /// Checks if a package name is in the approved registry.
  static bool isApprovedPackage(String packageName) {
    return resolveByPackage(packageName) != null;
  }
}
