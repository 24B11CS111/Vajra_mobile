import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/features/devices/models/device_model.dart';

void main() {
  group('EcosystemDevice Model Tests', () {
    test('fromJson deserializes complete backend payload correctly', () {
      final json = {
        'id': '11111111-2222-3333-4444-555555555555',
        'device_id': 'desktop_win_999',
        'device_type': 'desktop',
        'device_name': 'VAJRA Workstation',
        'platform': 'windows',
        'app_version': '1.0.0',
        'capabilities': ['files', 'terminal', 'developer', 'browser', 'apps'],
        'is_active': true,
        'last_seen': '2026-09-16T12:00:00Z',
        'created_at': '2026-09-16T11:00:00Z',
      };

      final device = EcosystemDevice.fromJson(json);

      expect(device.id, '11111111-2222-3333-4444-555555555555');
      expect(device.deviceId, 'desktop_win_999');
      expect(device.deviceType, 'desktop');
      expect(device.deviceName, 'VAJRA Workstation');
      expect(device.platform, 'windows');
      expect(device.appVersion, '1.0.0');
      expect(device.capabilities, contains('developer'));
      expect(device.capabilities.length, 5);
      expect(device.isActive, isTrue);
    });

    test('toJson serializes correctly', () {
      final device = EcosystemDevice(
        id: '2222',
        deviceId: 'android_001',
        deviceType: 'mobile',
        deviceName: 'Nothing Phone (2a)',
        platform: 'android',
        appVersion: '2.0.0',
        capabilities: ['call', 'sms', 'camera'],
        isActive: true,
        lastSeen: DateTime.parse('2026-09-16T10:00:00Z'),
        createdAt: DateTime.parse('2026-09-16T09:00:00Z'),
      );

      final json = device.toJson();

      expect(json['device_id'], 'android_001');
      expect(json['device_type'], 'mobile');
      expect(json['platform'], 'android');
      expect(json['capabilities'], contains('call'));
    });
  });
}
