import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a drafted SMS/text message awaiting explicit user approval.
class DraftedMessage {
  final String id;
  final String recipient;
  final String? recipientName;
  final String messageBody;
  final DateTime createdAt;
  final bool isConfirmed;
  final bool isSent;

  const DraftedMessage({
    required this.id,
    required this.recipient,
    this.recipientName,
    required this.messageBody,
    required this.createdAt,
    this.isConfirmed = false,
    this.isSent = false,
  });

  DraftedMessage copyWith({
    String? id,
    String? recipient,
    String? recipientName,
    String? messageBody,
    DateTime? createdAt,
    bool? isConfirmed,
    bool? isSent,
  }) {
    return DraftedMessage(
      id: id ?? this.id,
      recipient: recipient ?? this.recipient,
      recipientName: recipientName ?? this.recipientName,
      messageBody: messageBody ?? this.messageBody,
      createdAt: createdAt ?? this.createdAt,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      isSent: isSent ?? this.isSent,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'recipient': recipient,
    'recipientName': recipientName,
    'messageBody': messageBody,
    'createdAt': createdAt.toIso8601String(),
    'isConfirmed': isConfirmed,
    'isSent': isSent,
  };
}

/// Result of a message composition or sending action.
class MessageActionResult {
  final bool success;
  final String message;
  final DraftedMessage? draft;
  final bool requiresConfirmation;
  final String? errorCode;

  const MessageActionResult({
    required this.success,
    required this.message,
    this.draft,
    this.requiresConfirmation = false,
    this.errorCode,
  });

  factory MessageActionResult.needsApproval(DraftedMessage draft) {
    return MessageActionResult(
      success: true,
      message: 'Draft ready for ${draft.recipientName ?? draft.recipient}: "${draft.messageBody}". Confirm to send?',
      draft: draft,
      requiresConfirmation: true,
    );
  }

  factory MessageActionResult.success(String message, [DraftedMessage? draft]) {
    return MessageActionResult(
      success: true,
      message: message,
      draft: draft,
      requiresConfirmation: false,
    );
  }

  factory MessageActionResult.failure(String message, {String? errorCode, DraftedMessage? draft}) {
    return MessageActionResult(
      success: false,
      message: message,
      draft: draft,
      requiresConfirmation: false,
      errorCode: errorCode,
    );
  }
}

/// MessageAssistant safely creates and manages text message drafts and dispatch via Android SMS intent.
class MessageAssistant {
  static const MethodChannel _channel = MethodChannel('com.vajra.app/message_assistant');
  final MethodChannel channel;
  DraftedMessage? _activeDraft;

  MessageAssistant([MethodChannel? customChannel]) : channel = customChannel ?? _channel;

  DraftedMessage? get activeDraft => _activeDraft;

  /// Prepares a drafted message. This DOES NOT send the message automatically.
  /// It returns a draft requiring explicit user confirmation.
  MessageActionResult prepareDraft({
    required String recipient,
    required String body,
    String? recipientName,
  }) {
    final cleanRecipient = recipient.trim();
    final cleanBody = body.trim();

    if (cleanRecipient.isEmpty) {
      return MessageActionResult.failure(
        'Recipient cannot be empty.',
        errorCode: 'INVALID_RECIPIENT',
      );
    }
    if (cleanBody.isEmpty) {
      return MessageActionResult.failure(
        'Message text cannot be empty.',
        errorCode: 'EMPTY_BODY',
      );
    }

    final draft = DraftedMessage(
      id: 'draft_${DateTime.now().millisecondsSinceEpoch}',
      recipient: cleanRecipient,
      recipientName: recipientName,
      messageBody: cleanBody,
      createdAt: DateTime.now(),
      isConfirmed: false,
      isSent: false,
    );

    _activeDraft = draft;
    return MessageActionResult.needsApproval(draft);
  }

  /// Cancels and clears the current active draft.
  void clearDraft() {
    _activeDraft = null;
  }

  /// Confirms and dispatches the message via the native SMS provider or SMS intent.
  /// Explicit user approval is enforced before this can be invoked.
  Future<MessageActionResult> confirmAndSend([DraftedMessage? draftToConfirm]) async {
    final draft = draftToConfirm ?? _activeDraft;
    if (draft == null) {
      return MessageActionResult.failure(
        'No active message draft to send.',
        errorCode: 'NO_ACTIVE_DRAFT',
      );
    }

    try {
      final res = await channel.invokeMethod<Map<dynamic, dynamic>>('openSmsComposer', {
        'recipient': draft.recipient,
        'body': draft.messageBody,
      });

      final success = res?['success'] == true;
      if (success) {
        final sentDraft = draft.copyWith(isConfirmed: true, isSent: true);
        _activeDraft = null;
        return MessageActionResult.success(
          'Opened SMS composer for ${draft.recipientName ?? draft.recipient}.',
          sentDraft,
        );
      } else {
        return MessageActionResult.failure(
          res?['message']?.toString() ?? 'Unable to launch SMS composer.',
          errorCode: res?['error']?.toString(),
          draft: draft,
        );
      }
    } on PlatformException catch (e) {
      debugPrint('[MessageAssistant] PlatformException on confirmAndSend: ${e.message}');
      return MessageActionResult.failure(
        e.message ?? 'Failed to open messaging app.',
        errorCode: e.code,
        draft: draft,
      );
    } catch (e) {
      debugPrint('[MessageAssistant] Unexpected error on confirmAndSend: $e');
      return MessageActionResult.failure(
        'Unexpected error sending message: $e',
        errorCode: 'UNEXPECTED_ERROR',
        draft: draft,
      );
    }
  }
}

/// Provider for MessageAssistant.
final messageAssistantProvider = Provider<MessageAssistant>((ref) {
  return MessageAssistant();
});
