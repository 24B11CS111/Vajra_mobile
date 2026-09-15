import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/bridge/android_action_bridge.dart';

void main() {
  group('AndroidActionBridge with BridgeObservation', () {
    late AndroidActionBridge bridge;

    setUp(() {
      bridge = AndroidActionBridge();
    });

    test('validates url schemes and produces accurate failure observation', () async {
      final resEmpty = await bridge.openUrl('');
      expect(resEmpty.success, isFalse);
      expect(resEmpty.message, contains('Invalid URL format'));

      final resJs = await bridge.openUrl('javascript:alert(1)');
      expect(resJs.success, isFalse);
      expect(resJs.message, contains('unsupported scheme'));
    });

    test('openSupportedApp returns failure observation for unknown unapproved app', () async {
      final res = await bridge.openSupportedApp('malicious_or_unknown_app_123');
      expect(res.success, isFalse);
      expect(res.message, contains('not in the allowlisted'));
    });
  });
}
