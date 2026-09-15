import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/study_models.dart';
import '../models/study_session_model.dart';

abstract class StudyLocalDataSource {
  Future<void> cacheAssignments(List<AssignmentModel> assignments);
  Future<List<AssignmentModel>?> getCachedAssignments();
  Future<void> saveAssignment(AssignmentModel assignment);
  Future<void> deleteAssignment(String id);

  Future<void> cacheSubjects(List<SubjectModel> subjects);
  Future<List<SubjectModel>?> getCachedSubjects();
  Future<void> saveSubject(SubjectModel subject);
  Future<void> deleteSubject(String id);

  Future<void> cacheSessions(List<StudySessionModel> sessions);
  Future<List<StudySessionModel>?> getCachedSessions();
  Future<void> saveSession(StudySessionModel session);

  Future<void> clearCache();
}

class StudyLocalDataSourceImpl implements StudyLocalDataSource {
  static const String _assignmentsKey = 'cached_study_assignments';
  static const String _subjectsKey = 'cached_study_subjects';
  static const String _sessionsKey = 'cached_study_sessions';
  final String? _explicitUserId;
  static final Map<String, List<String>> _fallbackMemory = {};

  StudyLocalDataSourceImpl({String? userId}) : _explicitUserId = userId;

  Future<SharedPreferences?> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  Future<String> _getScopedKey(String baseKey) async {
    if (_explicitUserId != null && _explicitUserId.isNotEmpty) {
      return 'vajra_${_explicitUserId}_$baseKey';
    }
    final prefs = await _getPrefs();
    final userId = prefs?.getString('vajra_current_user_id');
    if (userId != null && userId.isNotEmpty) {
      return 'vajra_${userId}_$baseKey';
    }
    return 'vajra_$baseKey';
  }

  @override
  Future<void> cacheAssignments(List<AssignmentModel> assignments) async {
    final key = await _getScopedKey(_assignmentsKey);
    final jsonList = assignments.map((a) => jsonEncode(a.toJson())).toList();
    final prefs = await _getPrefs();
    if (prefs != null) {
      await prefs.setStringList(key, jsonList);
    } else {
      _fallbackMemory[key] = jsonList;
    }
  }

  @override
  Future<List<AssignmentModel>?> getCachedAssignments() async {
    final key = await _getScopedKey(_assignmentsKey);
    final prefs = await _getPrefs();
    final jsonList = prefs != null ? prefs.getStringList(key) : _fallbackMemory[key];
    if (jsonList != null) {
      try {
        return jsonList.map((j) => AssignmentModel.fromJson(jsonDecode(j) as Map<String, dynamic>)).toList();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> saveAssignment(AssignmentModel assignment) async {
    final current = await getCachedAssignments() ?? [];
    final index = current.indexWhere((a) => a.id == assignment.id);
    if (index >= 0) {
      current[index] = assignment;
    } else {
      current.insert(0, assignment);
    }
    await cacheAssignments(current);
  }

  @override
  Future<void> deleteAssignment(String id) async {
    final current = await getCachedAssignments() ?? [];
    current.removeWhere((a) => a.id == id);
    await cacheAssignments(current);
  }

  @override
  Future<void> cacheSubjects(List<SubjectModel> subjects) async {
    final key = await _getScopedKey(_subjectsKey);
    final jsonList = subjects.map((s) => jsonEncode(s.toJson())).toList();
    final prefs = await _getPrefs();
    if (prefs != null) {
      await prefs.setStringList(key, jsonList);
    } else {
      _fallbackMemory[key] = jsonList;
    }
  }

  @override
  Future<List<SubjectModel>?> getCachedSubjects() async {
    final key = await _getScopedKey(_subjectsKey);
    final prefs = await _getPrefs();
    final jsonList = prefs != null ? prefs.getStringList(key) : _fallbackMemory[key];
    if (jsonList != null) {
      try {
        return jsonList.map((j) => SubjectModel.fromJson(jsonDecode(j) as Map<String, dynamic>)).toList();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> saveSubject(SubjectModel subject) async {
    final current = await getCachedSubjects() ?? [];
    final index = current.indexWhere((s) => s.id == subject.id);
    if (index >= 0) {
      current[index] = subject;
    } else {
      current.insert(0, subject);
    }
    await cacheSubjects(current);
  }

  @override
  Future<void> deleteSubject(String id) async {
    final current = await getCachedSubjects() ?? [];
    current.removeWhere((s) => s.id == id);
    await cacheSubjects(current);
  }

  @override
  Future<void> cacheSessions(List<StudySessionModel> sessions) async {
    final key = await _getScopedKey(_sessionsKey);
    final jsonList = sessions.map((s) => jsonEncode(s.toJson())).toList();
    final prefs = await _getPrefs();
    if (prefs != null) {
      await prefs.setStringList(key, jsonList);
    } else {
      _fallbackMemory[key] = jsonList;
    }
  }

  @override
  Future<List<StudySessionModel>?> getCachedSessions() async {
    final key = await _getScopedKey(_sessionsKey);
    final prefs = await _getPrefs();
    final jsonList = prefs != null ? prefs.getStringList(key) : _fallbackMemory[key];
    if (jsonList != null) {
      try {
        return jsonList.map((j) => StudySessionModel.fromJson(jsonDecode(j) as Map<String, dynamic>)).toList();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> saveSession(StudySessionModel session) async {
    final current = await getCachedSessions() ?? [];
    final index = current.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      current[index] = session;
    } else {
      current.insert(0, session);
    }
    await cacheSessions(current);
  }

  @override
  Future<void> clearCache() async {
    final assignKey = await _getScopedKey(_assignmentsKey);
    final subjKey = await _getScopedKey(_subjectsKey);
    final sessKey = await _getScopedKey(_sessionsKey);
    final prefs = await _getPrefs();
    if (prefs != null) {
      await prefs.remove(assignKey);
      await prefs.remove(subjKey);
      await prefs.remove(sessKey);
    }
    _fallbackMemory.remove(assignKey);
    _fallbackMemory.remove(subjKey);
    _fallbackMemory.remove(sessKey);
  }
}

final studyLocalDataSourceProvider = Provider<StudyLocalDataSource>((ref) {
  return StudyLocalDataSourceImpl();
});
