import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Type of offline mutation queued.
enum SyncOperationType {
  create,
  update,
  delete,
}

/// Synchronization status of an entity.
enum EntitySyncStatus {
  synced,
  pendingCreate,
  pendingUpdate,
  pendingDelete,
  syncFailed,
}

/// Represents an item in the offline sync queue.
class QueuedSyncOperation {
  final String id;
  final String entityType; // 'planner_task', 'calendar_event', 'assignment', 'subject', 'study_session', 'memory'
  final String entityId;
  final SyncOperationType operation;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  const QueuedSyncOperation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'entityType': entityType,
        'entityId': entityId,
        'operation': operation.name,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
      };

  factory QueuedSyncOperation.fromJson(Map<String, dynamic> json) {
    return QueuedSyncOperation(
      id: json['id'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String? ?? json['id'] as String,
      operation: SyncOperationType.values.firstWhere(
        (e) => e.name == json['operation'],
        orElse: () => SyncOperationType.create,
      ),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  QueuedSyncOperation copyWith({
    int? retryCount,
  }) {
    return QueuedSyncOperation(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: payload,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

/// State for the SyncQueue.
class SyncQueueState {
  final List<QueuedSyncOperation> pendingOperations;
  final bool isSyncing;
  final bool isOnline;
  final DateTime? lastSuccessfulSync;

  const SyncQueueState({
    this.pendingOperations = const [],
    this.isSyncing = false,
    this.isOnline = true,
    this.lastSuccessfulSync,
  });

  SyncQueueState copyWith({
    List<QueuedSyncOperation>? pendingOperations,
    bool? isSyncing,
    bool? isOnline,
    DateTime? lastSuccessfulSync,
  }) {
    return SyncQueueState(
      pendingOperations: pendingOperations ?? this.pendingOperations,
      isSyncing: isSyncing ?? this.isSyncing,
      isOnline: isOnline ?? this.isOnline,
      lastSuccessfulSync: lastSuccessfulSync ?? this.lastSuccessfulSync,
    );
  }
}

/// SyncQueue manages offline operations and synchronizes them with the backend.
class SyncQueue extends StateNotifier<SyncQueueState> {
  static const String _storageKey = 'vajra_pending_sync_queue';
  final String? _explicitUserId;

  SyncQueue({String? userId})
      : _explicitUserId = userId,
        super(const SyncQueueState()) {
    _loadFromStorage();
  }

  Future<String> _getStorageKey() async {
    if (_explicitUserId != null && _explicitUserId.isNotEmpty) {
      return 'vajra_${_explicitUserId}_pending_sync_queue';
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('vajra_current_user_id');
      if (userId != null && userId.isNotEmpty) {
        return 'vajra_${userId}_pending_sync_queue';
      }
    } catch (_) {}
    return _storageKey;
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getStorageKey();
      final jsonList = prefs.getStringList(key);
      if (jsonList != null) {
        final ops = jsonList
            .map((j) => QueuedSyncOperation.fromJson(jsonDecode(j) as Map<String, dynamic>))
            .toList();
        state = state.copyWith(pendingOperations: ops);
      }
    } catch (_) {}
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getStorageKey();
      final jsonList = state.pendingOperations.map((op) => jsonEncode(op.toJson())).toList();
      await prefs.setStringList(key, jsonList);
    } catch (_) {}
  }

  Future<void> clearQueue() async {
    state = state.copyWith(pendingOperations: []);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getStorageKey();
      await prefs.remove(key);
      await prefs.remove(_storageKey);
    } catch (_) {}
  }

  void setOnlineStatus(bool online) {
    if (state.isOnline != online) {
      state = state.copyWith(isOnline: online);
    }
  }

  /// Enqueues an offline operation with deduplication.
  Future<void> enqueue({
    required String entityType,
    String? entityId,
    required SyncOperationType operation,
    required Map<String, dynamic> payload,
  }) async {
    final effectiveEntityId = entityId ?? payload['id']?.toString() ?? 'entity_${DateTime.now().microsecondsSinceEpoch}';
    final updated = List<QueuedSyncOperation>.from(state.pendingOperations);

    // If an operation on the same entity exists, handle cleanly
    final existingIndex = updated.indexWhere((op) => op.entityType == entityType && op.entityId == effectiveEntityId);

    if (existingIndex >= 0) {
      final existing = updated[existingIndex];
      if (operation == SyncOperationType.delete && existing.operation == SyncOperationType.create) {
        // Created and deleted offline before syncing to server: drop completely
        updated.removeAt(existingIndex);
      } else {
        updated[existingIndex] = QueuedSyncOperation(
          id: existing.id,
          entityType: entityType,
          entityId: effectiveEntityId,
          operation: operation,
          payload: {...existing.payload, ...payload},
          createdAt: DateTime.now(),
        );
      }
    } else {
      updated.add(QueuedSyncOperation(
        id: 'sync_${DateTime.now().microsecondsSinceEpoch}',
        entityType: entityType,
        entityId: effectiveEntityId,
        operation: operation,
        payload: payload,
        createdAt: DateTime.now(),
      ));
    }

    state = state.copyWith(pendingOperations: updated);
    await _saveToStorage();
  }

  /// Processes and flushes all queued sync operations.
  Future<void> flushQueue(Future<bool> Function(QueuedSyncOperation) syncExecutor) async {
    if (state.pendingOperations.isEmpty || state.isSyncing) return;

    state = state.copyWith(isSyncing: true);
    final remaining = <QueuedSyncOperation>[];

    for (final op in state.pendingOperations) {
      try {
        final success = await syncExecutor(op);
        if (!success) {
          remaining.add(op.copyWith(retryCount: op.retryCount + 1));
        }
      } catch (_) {
        remaining.add(op.copyWith(retryCount: op.retryCount + 1));
      }
    }

    state = state.copyWith(
      pendingOperations: remaining,
      isSyncing: false,
      lastSuccessfulSync: remaining.isEmpty ? DateTime.now() : state.lastSuccessfulSync,
    );
    await _saveToStorage();
  }

  /// Resolves conflicts using timestamp-based Last-Write-Wins strategy.
  Map<String, dynamic> resolveConflict(Map<String, dynamic> local, Map<String, dynamic> remote) {
    final localTime = DateTime.tryParse(local['updated_at']?.toString() ?? '') ?? DateTime(1970);
    final remoteTime = DateTime.tryParse(remote['updated_at']?.toString() ?? '') ?? DateTime(1970);

    return localTime.isAfter(remoteTime) ? local : remote;
  }
}

/// Provider for SyncQueue.
final syncQueueProvider = StateNotifierProvider<SyncQueue, SyncQueueState>((ref) {
  return SyncQueue();
});
