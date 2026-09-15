import 'package:flutter/foundation.dart';

class TelemetryService {
  static void trackEvent(String eventName, [Map<String, dynamic>? data]) {
    // In production, syncs anonymously via ApiClient background queue
    debugPrint("TELEMETRY: $eventName");
  }
}
