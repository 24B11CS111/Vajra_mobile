import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/sse_client.dart';
import '../models/stream_event.dart';

final companionRepositoryProvider = Provider<CompanionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CompanionRepository(SseClient(apiClient.dio));
});

class CompanionRepository {
  final SseClient _sseClient;
  CompanionRepository(this._sseClient);

  Stream<BackendStreamEvent> processConversation(String sessionId, String text) async* {
    final payload = {
      "session_id": sessionId,
      "text": text,
      "modality": "TEXT",
      "context_overrides": {}
    };

    await for (final sse in _sseClient.postStream(ApiEndpoints.processConversation, data: payload)) {
      if (sse.data.isNotEmpty) {
        try {
          final json = jsonDecode(sse.data);
          yield BackendStreamEvent.fromJson(json);
        } catch (e) {
          // Fallback or log parse error
        }
      }
    }
  }
}
