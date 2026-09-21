class EcosystemDevice {
  final String id;
  final String deviceId;
  final String deviceType;
  final String deviceName;
  final String platform;
  final String? appVersion;
  final List<String> capabilities;
  final bool isActive;
  final DateTime lastSeen;
  final DateTime createdAt;

  const EcosystemDevice({
    required this.id,
    required this.deviceId,
    required this.deviceType,
    required this.deviceName,
    required this.platform,
    this.appVersion,
    required this.capabilities,
    required this.isActive,
    required this.lastSeen,
    required this.createdAt,
  });

  factory EcosystemDevice.fromJson(Map<String, dynamic> json) {
    return EcosystemDevice(
      id: json['id']?.toString() ?? '',
      deviceId: json['device_id']?.toString() ?? '',
      deviceType: json['device_type']?.toString() ?? 'unknown',
      deviceName: json['device_name']?.toString() ?? 'Device',
      platform: json['platform']?.toString() ?? 'unknown',
      appVersion: json['app_version']?.toString(),
      capabilities: (json['capabilities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isActive: json['is_active'] == true,
      lastSeen: DateTime.tryParse(json['last_seen']?.toString() ?? '') ??
          DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'device_type': deviceType,
      'device_name': deviceName,
      'platform': platform,
      'app_version': appVersion,
      'capabilities': capabilities,
      'is_active': isActive,
      'last_seen': lastSeen.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
