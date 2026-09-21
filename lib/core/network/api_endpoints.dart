import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Production URL for VAJRA Cloud Backend
  static const String defaultProductionUrl = 'https://vajra-api-rslc.onrender.com/api/v1';
  static const String defaultDevelopmentUrl = 'http://10.0.2.2:8000/api/v1';

  // Configured via --dart-define=API_BASE_URL=https://...
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    if (kReleaseMode) {
      return defaultProductionUrl;
    }
    return defaultDevelopmentUrl;
  }
  
  static const String signup = '/auth/signup';
  static const String login = '/auth/login';
  static const String socialLogin = '/auth/social';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String changePassword = '/auth/change-password';
  static const String deleteAccount = '/auth/account';
  
  static const String me = '/me';
  static const String conversations = '/chat/conversations';
  static const String memory = '/memory/';
  static const String memoryPurge = '/memory/purge';
  static const String plannerTasks = '/planner/tasks';
  static const String notifications = '/notifications/';
  static const String processConversation = '/chat/conversations';
  
  static const String subjects = '/study/subjects';
  static const String assignments = '/study/assignments';
  static const String calendarEvents = '/calendar/events';
  static const String devices = '/devices';
  static const String registerDevice = '/devices/register';
  static const String pendingActions = '/devices/actions/pending';
  static const String dispatchAction = '/devices/actions/dispatch';
}
