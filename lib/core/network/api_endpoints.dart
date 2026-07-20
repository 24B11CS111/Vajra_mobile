class ApiEndpoints {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS Simulator
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
  
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String processConversation = '/conversation/stream';
}
