import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_repository.dart';
import '../../profile/providers/profile_provider.dart';
import '../../companion/providers/companion_provider.dart';
import '../../memory/providers/memory_provider.dart';
import '../../planner/providers/planner_provider.dart';
import '../../study/providers/study_provider.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref? _ref;

  AuthNotifier(this._repository, [this._ref]) : super(AuthState.initial) {
    _checkAuth();
  }

  void _resetUserProviders() {
    if (_ref != null) {
      try {
        _ref.invalidate(profileProvider);
        _ref.invalidate(companionProfileProvider);
        _ref.invalidate(companionProvider);
        _ref.invalidate(memoryProvider);
        _ref.invalidate(plannerProvider);
        _ref.invalidate(calendarEventsProvider);
        _ref.invalidate(assignmentsProvider);
        _ref.invalidate(subjectsProvider);
      } catch (_) {}
    }
  }

  Future<void> _checkAuth() async {
    final isLoggedIn = await _repository.restoreSession();
    if (isLoggedIn) {
      state = AuthState.authenticated;
    } else {
      state = AuthState.unauthenticated;
    }
  }

  Future<void> signup(String email, String password, String? fullName) async {
    state = AuthState.loading;
    final result = await _repository.signup(email, password, fullName);
    if (result.isSuccess) {
      _resetUserProviders();
      state = AuthState.authenticated;
    } else {
      state = AuthState.error;
    }
  }

  Future<void> login(String username, String password) async {
    state = AuthState.loading;
    final result = await _repository.login(username, password);
    if (result.isSuccess) {
      _resetUserProviders();
      state = AuthState.authenticated;
    } else {
      state = AuthState.error;
    }
  }

  Future<void> socialLogin(AuthProviderType provider) async {
    state = AuthState.loading;
    final result = await _repository.socialLogin(provider, 'mock_oauth_token');
    if (result.isSuccess) {
      _resetUserProviders();
      state = AuthState.authenticated;
    } else {
      state = AuthState.error;
    }
  }

  Future<void> guestLogin() async {
    state = AuthState.loading;
    final result = await _repository.guestLogin();
    if (result.isSuccess) {
      _resetUserProviders();
      state = AuthState.authenticated;
    } else {
      state = AuthState.error;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _resetUserProviders();
    state = AuthState.unauthenticated;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider), ref);
});
