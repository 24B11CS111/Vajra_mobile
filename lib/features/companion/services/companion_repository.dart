import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/sse_client.dart';
import '../models/stream_event.dart';

final companionRepositoryProvider = Provider<CompanionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CompanionRepository(apiClient, SseClient(apiClient.dio));
});

class CompanionRepository {
  final ApiClient _apiClient;
  final SseClient _sseClient;
  String? _activeConversationId;

  CompanionRepository(this._apiClient, this._sseClient);

  void resetActiveConversation() {
    _activeConversationId = null;
  }

  Future<String> _getOrCreateConversation(String sessionId) async {
    if (_activeConversationId != null) return _activeConversationId!;
    try {
      final listRes = await _apiClient.get(ApiEndpoints.conversations);
      if (listRes.data is List && (listRes.data as List).isNotEmpty) {
        _activeConversationId = (listRes.data as List).first['id'].toString();
        return _activeConversationId!;
      }
    } catch (_) {}

    try {
      final createRes = await _apiClient.post(
        ApiEndpoints.conversations,
        data: {'title': 'VAJRA Companion Session'},
      );
      _activeConversationId = createRes.data['id'].toString();
      return _activeConversationId!;
    } catch (_) {
      return sessionId;
    }
  }

  Stream<BackendStreamEvent> processConversation(String sessionId, String text) async* {
    final conversationId = await _getOrCreateConversation(sessionId);
    final streamUrl = '${ApiEndpoints.conversations}/$conversationId/messages/stream';

    final payload = {
      "role": "user",
      "content": text,
    };

    yield const BackendStreamEvent(
      eventType: EventType.thinking,
      payload: {},
    );

    try {
      await for (final sse in _sseClient.postStream(streamUrl, data: payload)) {
        if (sse.data.isNotEmpty) {
          try {
            final json = jsonDecode(sse.data) as Map<String, dynamic>;
            if (json.containsKey('error')) {
              yield BackendStreamEvent(
                eventType: EventType.error,
                payload: {'error': json['error']},
              );
            } else if (json.containsKey('delta')) {
              yield BackendStreamEvent(
                eventType: EventType.token,
                payload: {'text': json['delta']},
              );
            } else if (json.containsKey('token')) {
              yield BackendStreamEvent(
                eventType: EventType.token,
                payload: {'text': json['token']},
              );
            } else if (json.containsKey('event_type')) {
              yield BackendStreamEvent.fromJson(json);
            } else if (json.containsKey('done') && json['done'] == true) {
              yield const BackendStreamEvent(
                eventType: EventType.complete,
                payload: {},
              );
            }
          } catch (_) {
            yield BackendStreamEvent(
              eventType: EventType.token,
              payload: {'text': sse.data},
            );
          }
        }
      }
      yield const BackendStreamEvent(
        eventType: EventType.complete,
        payload: {},
      );
    } catch (e) {
      yield BackendStreamEvent(
        eventType: EventType.error,
        payload: {'error': e.toString()},
      );
    }
  }
}
