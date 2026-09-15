import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/intelligence/sync/sync_queue.dart';

void main() {
  group('SyncQueue', () {
    late SyncQueue queue;

    setUp(() {
      queue = SyncQueue();
    });

    test('enqueues sync operations', () {
      queue.enqueue(
        entityType: 'planner',
        operation: SyncOperationType.create,
        payload: {'title': 'Offline Study Task'},
      );

      expect(queue.state.pendingOperations.length, 1);
      expect(queue.state.pendingOperations.first.entityType, 'planner');
    });

    test('flushes queue upon executor success', () async {
      queue.enqueue(
        entityType: 'memory',
        operation: SyncOperationType.create,
        payload: {'content': 'Offline memory'},
      );

      await queue.flushQueue((op) async => true);
      expect(queue.state.pendingOperations, isEmpty);
      expect(queue.state.lastSuccessfulSync, isNotNull);
    });

    test('resolves conflict using last write wins', () {
      final older = {'updated_at': '2026-08-23T10:00:00Z', 'value': 'old'};
      final newer = {'updated_at': '2026-08-23T12:00:00Z', 'value': 'new'};

      final resolved = queue.resolveConflict(older, newer);
      expect(resolved['value'], 'new');
    });
  });
}
