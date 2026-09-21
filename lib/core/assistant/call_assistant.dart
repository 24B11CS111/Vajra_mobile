import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Result of a contact search query.
class ContactResult {
  final String id;
  final String displayName;
  final String phoneNumber;
  final String? photoUri;

  const ContactResult({
    required this.id,
    required this.displayName,
    required this.phoneNumber,
    this.photoUri,
  });

  factory ContactResult.fromMap(Map<dynamic, dynamic> map) {
    return ContactResult(
      id: map['id']?.toString() ?? '',
      displayName: map['name']?.toString() ?? map['displayName']?.toString() ?? '',
      phoneNumber: map['phone']?.toString() ?? map['phoneNumber']?.toString() ?? '',
      photoUri: map['photoUri']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'displayName': displayName,
    'phoneNumber': phoneNumber,
    'photoUri': photoUri,
  };
}

/// Status and metadata returned by call actions.
class CallActionResult {
  final bool success;
  final String message;
  final String? phoneNumber;
  final String? contactName;
  final bool openedDialer;
  final String? errorCode;

  const CallActionResult({
    required this.success,
    required this.message,
    this.phoneNumber,
    this.contactName,
    this.openedDialer = false,
    this.errorCode,
  });

  factory CallActionResult.success({
    required String message,
    String? phoneNumber,
    String? contactName,
    bool openedDialer = false,
  }) {
    return CallActionResult(
      success: true,
      message: message,
      phoneNumber: phoneNumber,
      contactName: contactName,
      openedDialer: openedDialer,
    );
  }

  factory CallActionResult.failure({
    required String message,
    String? errorCode,
    String? phoneNumber,
    String? contactName,
  }) {
    return CallActionResult(
      success: false,
      message: message,
      errorCode: errorCode,
      phoneNumber: phoneNumber,
      contactName: contactName,
    );
  }
}

/// CallAssistant manages native telephony, dialer launch, and contact searches.
class CallAssistant {
  static const MethodChannel _channel = MethodChannel('com.vajra.app/call_assistant');
  final MethodChannel channel;

  CallAssistant([MethodChannel? customChannel]) : channel = customChannel ?? _channel;

  /// Searches for contacts matching [query] by name or phone number.
  Future<List<ContactResult>> findContacts(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      final List<dynamic>? results = await channel.invokeMethod('searchContacts', {
        'query': cleanQuery,
      });

      if (results == null) return [];
      return results
          .whereType<Map<dynamic, dynamic>>()
          .map((m) => ContactResult.fromMap(m))
          .toList();
    } on PlatformException catch (e) {
      debugPrint('[CallAssistant] findContacts platform error: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('[CallAssistant] findContacts error: $e');
      return [];
    }
  }

  /// Initiates a phone call to [phoneNumber] or contact name.
  /// If [directCall] is true and CALL_PHONE permission is available, it makes an immediate call.
  /// Otherwise, it safely launches the system dialer pre-populated with the number.
  Future<CallActionResult> makeCall({
    required String phoneNumber,
    String? contactName,
    bool directCall = false,
  }) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanNumber.isEmpty) {
      return CallActionResult.failure(
        message: 'Invalid phone number provided.',
        errorCode: 'INVALID_NUMBER',
        contactName: contactName,
      );
    }

    try {
      final res = await channel.invokeMethod<Map<dynamic, dynamic>>('makeCall', {
        'phoneNumber': cleanNumber,
        'contactName': contactName,
        'directCall': directCall,
      });

      final success = res?['success'] == true;
      final msg = res?['message']?.toString() ?? (success ? 'Calling $cleanNumber' : 'Could not make call.');
      final dialerOpened = res?['openedDialer'] == true;

      return CallActionResult(
        success: success,
        message: msg,
        phoneNumber: cleanNumber,
        contactName: contactName,
        openedDialer: dialerOpened,
        errorCode: res?['error']?.toString(),
      );
    } on PlatformException catch (e) {
      debugPrint('[CallAssistant] makeCall platform exception: ${e.message}');
      return CallActionResult.failure(
        message: e.message ?? 'Failed to initiate phone call.',
        errorCode: e.code,
        phoneNumber: cleanNumber,
        contactName: contactName,
      );
    } catch (e) {
      debugPrint('[CallAssistant] makeCall unexpected error: $e');
      return CallActionResult.failure(
        message: 'Could not connect to dialer: $e',
        errorCode: 'UNEXPECTED_ERROR',
        phoneNumber: cleanNumber,
        contactName: contactName,
      );
    }
  }

  /// Opens the device dialer, optionally pre-populating with [phoneNumber].
  Future<CallActionResult> openDialer([String? phoneNumber]) async {
    try {
      final clean = phoneNumber?.replaceAll(RegExp(r'[^\d+]'), '');
      await channel.invokeMethod('openDialer', {
        if (clean != null && clean.isNotEmpty) 'phoneNumber': clean,
      });

      return CallActionResult.success(
        message: clean != null ? 'Opened dialer with $clean' : 'Opened phone dialer.',
        phoneNumber: clean,
        openedDialer: true,
      );
    } on PlatformException catch (e) {
      return CallActionResult.failure(
        message: e.message ?? 'Unable to open dialer.',
        errorCode: e.code,
        phoneNumber: phoneNumber,
      );
    } catch (e) {
      return CallActionResult.failure(
        message: 'Error launching dialer: $e',
        errorCode: 'DIALER_LAUNCH_ERROR',
        phoneNumber: phoneNumber,
      );
    }
  }
}

/// Provider for CallAssistant.
final callAssistantProvider = Provider<CallAssistant>((ref) {
  return CallAssistant();
});
