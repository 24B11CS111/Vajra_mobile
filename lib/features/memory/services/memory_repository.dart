import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
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

  @override
  Future<List<MemoryModel>> getMemories(String? category) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Simulated remote data
    return [
      MemoryModel(
        id: '1',
        content: 'User prefers dark mode and minimalist aesthetics.',
        category: 'Preferences',
        importanceScore: 0.9,
        isPinned: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      MemoryModel(
        id: '2',
        content: 'Studying for Physics midterms on Friday.',
        category: 'Study',
        importanceScore: 0.8,
        isPinned: false,
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<void> syncPinStatus(String id, bool isPinned) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
  
  @override
  Future<void> deleteMemory(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> archiveMemory(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> importMemories(List<MemoryModel> memories) async {
    await Future.delayed(const Duration(milliseconds: 800));
  }
}

abstract class MemoryLocalDataSource {
  Future<void> cacheMemories(List<MemoryModel> memories, String? category);
  Future<List<MemoryModel>?> getCachedMemories(String? category);
  Future<void> clearCache();
}

class MemoryLocalDataSourceImpl implements MemoryLocalDataSource {
  String _getCacheKey(String? category) => 'cached_memories_${category ?? "all"}';

  @override
  Future<void> cacheMemories(List<MemoryModel> memories, String? category) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = memories.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList(_getCacheKey(category), jsonList);
  }

  @override
  Future<List<MemoryModel>?> getCachedMemories(String? category) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_getCacheKey(category));
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
    final keys = prefs.getKeys().where((k) => k.startsWith('cached_memories_'));
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
