import 'dart:convert';
import 'package:dio/dio.dart';

class SseEvent {
  final String event;
  final String data;
  SseEvent(this.event, this.data);
}

class SseClient {
  final Dio _dio;
  SseClient(this._dio);

  Stream<SseEvent> postStream(String path, {dynamic data}) async* {
    final response = await _dio.post<ResponseBody>(
      path,
      data: data,
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/event-stream'},
      ),
    );

    if (response.data == null) return;

    final stream = response.data!.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    String currentEvent = '';
    String currentData = '';

    await for (final line in stream) {
      if (line.isEmpty) {
        if (currentEvent.isNotEmpty || currentData.isNotEmpty) {
          yield SseEvent(currentEvent, currentData);
          currentEvent = '';
          currentData = '';
        }
      } else if (line.startsWith('event:')) {
        currentEvent = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        currentData = line.substring(5).trim();
      }
    }

    if (currentEvent.isNotEmpty || currentData.isNotEmpty) {
      yield SseEvent(currentEvent, currentData);
    }
  }
}
