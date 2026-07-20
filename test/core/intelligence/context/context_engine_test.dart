import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/intelligence/context/context_engine.dart';

void main() {
  group('ContextEngine', () {
    late ContextEngine engine;

    setUp(() {
      engine = ContextEngine();
    });

    test('initial state has current time', () {
      final state = engine.capture();
      expect(state.currentTime, isNotNull);
      expect(state.currentScreen, 'home');
      expect(state.recentActivity, 'idle');
    });

    test('update modifies context values', () {
      engine.update(
        currentScreen: 'settings',
        recentActivity: 'browsing',
        isConnected: false,
        batteryLevel: 0.5,
        userMode: 'study',
      );

      final state = engine.capture();
      expect(state.currentScreen, 'settings');
      expect(state.recentActivity, 'browsing');
      expect(state.isConnected, false);
      expect(state.batteryLevel, 0.5);
      expect(state.userMode, 'study');
    });
  });
}
