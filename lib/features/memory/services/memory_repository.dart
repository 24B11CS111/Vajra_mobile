import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../models/memory_model.dart';

abstract class MemoryRemoteDataSource {
  Future<List<MemoryModel>> getMemories(String? category);
  Future<void> syncPinStatus(String id, bool isPinned);
  Future<void> deleteMemory(String id);
  Future<void> archiveMemory(String id);
  Future<void> importMemories(List<MemoryModel> memories);
}

class MemoryRemoteDataSourceImpl implements MemoryRemoteDataSource {
  final ApiClient _apiClient;

  MemoryRemoteDataSourceImpl(this._apiClient);

  MemoryModel _fromBackendJson(Map<String, dynamic> json) {
    return MemoryModel(
      id: json['id']?.toString() ?? '',
      content: json['content'] ?? '',
      category: json['memory_type']?.toString() ?? json['category']?.toString() ?? 'General',
      importanceScore: (json['importance'] as num?)?.toDouble() ?? (json['importanceScore'] as num?)?.toDouble() ?? 0.5,
      isPinned: json['favorite'] == true || json['isPinned'] == true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      source: json['source']?.toString() ?? 'VAJRA Core',
    );
  }

  @override
  Future<List<MemoryModel>> getMemories(String? category) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.memory,
        queryParameters: category != null && category.isNotEmpty ? {'query': category} : null,
      );
      if (response.data is List) {
        return (response.data as List)
            .map((item) => _fromBackendJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to fetch memories');
    }
  }

  @override
  Future<void> syncPinStatus(String id, bool isPinned) async {
    try {
      await _apiClient.post('${ApiEndpoints.memory}$id/favorite');
    } catch (_) {}
  }
  
  @override
  Future<void> deleteMemory(String id) async {
    try {
      await _apiClient.delete('${ApiEndpoints.memory}$id');
    } catch (_) {}
  }

  @override
  Future<void> archiveMemory(String id) async {
    try {
      await _apiClient.post('${ApiEndpoints.memory}$id/archive');
    } catch (_) {}
  }

  String _mapCategoryToMemoryType(String category) {
    final lower = category.trim().toLowerCase();
    const valid = {
      'fact', 'preference', 'goal', 'task', 'reminder', 'project',
      'conversation_summary', 'person', 'place', 'knowledge', 'device', 'automation', 'custom'
    };
    if (valid.contains(lower)) return lower;
    if (lower == 'preferences') return 'preference';
    if (lower == 'study' || lower == 'education') return 'knowledge';
    if (lower == 'work' || lower == 'business') return 'project';
    return 'custom';
  }

  @override
  Future<void> importMemories(List<MemoryModel> memories) async {
    for (final memory in memories) {
      try {
        await _apiClient.post(
          ApiEndpoints.memory,
          data: {
            'content': memory.content,
            'memory_type': _mapCategoryToMemoryType(memory.category),
            'importance': memory.importanceScore,
            'favorite': memory.isPinned,
            'source': memory.source,
          },
        );
      } catch (_) {}
    }
  }
}

abstract class MemoryLocalDataSource {
  Future<void> cacheMemories(List<MemoryModel> memories, String? category);
  Future<List<MemoryModel>?> getCachedMemories(String? category);
  Future<void> clearCache();
}

class MemoryLocalDataSourceImpl implements MemoryLocalDataSource {
  final String? _explicitUserId;

  MemoryLocalDataSourceImpl({String? userId}) : _explicitUserId = userId;

  Future<String> _getCacheKey(String? category) async {
    final base = 'cached_memories_${category ?? "all"}';
    if (_explicitUserId != null && _explicitUserId.isNotEmpty) {
      return 'vajra_${_explicitUserId}_$base';
    }
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('vajra_current_user_id');
    if (userId != null && userId.isNotEmpty) {
      return 'vajra_${userId}_$base';
    }
    return 'vajra_$base';
  }

  @override
  Future<void> cacheMemories(List<MemoryModel> memories, String? category) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getCacheKey(category);
    final jsonList = memories.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList(key, jsonList);
  }

  @override
  Future<List<MemoryModel>?> getCachedMemories(String? category) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getCacheKey(category);
    final jsonList = prefs.getStringList(key);
    if (jsonList != null) {
      try {
        return jsonList.map((j) => MemoryModel.fromJson(jsonDecode(j))).toList();
      } catch (_) {
        return null;
      }
    }
    return null;
  }
  
  @override
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.contains('cached_memories_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}

abstract class MemoryRepository {
  Future<ApiResponse<List<MemoryModel>>> getMemories({String? category});
  Future<ApiResponse<bool>> syncPinStatus(String id, bool isPinned);
  Future<ApiResponse<bool>> deleteMemory(String id);
  Future<ApiResponse<bool>> archiveMemory(String id);
  Future<ApiResponse<String>> exportMemories();
  Future<ApiResponse<bool>> importMemories(String jsonString);
  Future<ApiResponse<bool>> saveFact(String content, {String category = 'fact'});
}

class MemoryRepositoryImpl implements MemoryRepository {
  final MemoryRemoteDataSource _remoteDataSource;
  final MemoryLocalDataSource _localDataSource;

  MemoryRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<ApiResponse<List<MemoryModel>>> getMemories({String? category}) async {
    try {
      final memories = await _remoteDataSource.getMemories(category);
      await _localDataSource.cacheMemories(memories, category);
      return ApiResponse.success(memories);
    } on DioException catch (e) {
      final cached = await _localDataSource.getCachedMemories(category);
      if (cached != null) return ApiResponse.success(cached);
      return ApiResponse.error(e.message ?? 'Network error and no cache');
    } catch (e) {
      final cached = await _localDataSource.getCachedMemories(category);
      if (cached != null) return ApiResponse.success(cached);
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<bool>> syncPinStatus(String id, bool isPinned) async {
    try {
      await _remoteDataSource.syncPinStatus(id, isPinned);
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
  
  @override
  Future<ApiResponse<bool>> deleteMemory(String id) async {
    try {
      await _remoteDataSource.deleteMemory(id);
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<bool>> archiveMemory(String id) async {
    try {
      await _remoteDataSource.archiveMemory(id);
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<String>> exportMemories() async {
    try {
      final cached = await _localDataSource.getCachedMemories(null);
      if (cached != null) {
        final jsonList = cached.map((m) => m.toJson()).toList();
        return ApiResponse.success(jsonEncode(jsonList));
      }
      return ApiResponse.error("No memories to export");
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<bool>> importMemories(String jsonString) async {
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      final memories = decoded.map((e) => MemoryModel.fromJson(e)).toList();
      await _remoteDataSource.importMemories(memories);
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<bool>> saveFact(String content, {String category = 'fact'}) async {
    try {
      final newMemory = MemoryModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        category: category,
        importanceScore: 0.8,
        isPinned: false,
        createdAt: DateTime.now(),
        source: 'Companion AI',
      );
      final existing = await _localDataSource.getCachedMemories(null) ?? [];
      await _localDataSource.cacheMemories([newMemory, ...existing], null);

      try {
        await _remoteDataSource.importMemories([newMemory]);
      } catch (_) {}

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}

final memoryRemoteDataSourceProvider = Provider<MemoryRemoteDataSource>((ref) {
  return MemoryRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final memoryLocalDataSourceProvider = Provider<MemoryLocalDataSource>((ref) {
  return MemoryLocalDataSourceImpl();
});

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return MemoryRepositoryImpl(
    ref.watch(memoryRemoteDataSourceProvider),
    ref.watch(memoryLocalDataSourceProvider),
  );
});
