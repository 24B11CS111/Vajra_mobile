import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_repository.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState.initial) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isLoggedIn = await _repository.restoreSession();
    state = isLoggedIn ? AuthState.authenticated : AuthState.unauthenticated;
  }

  Future<void> login(String username, String password) async {
    state = AuthState.loading;
    final result = await _repository.login(username, password);
    if (result.isSuccess) {
      state = AuthState.authenticated;
    } else {
      state = AuthState.error;
    }
  }

  Future<void> socialLogin(AuthProviderType provider) async {
    state = AuthState.loading;
    // In a real implementation, we would launch the provider's SDK here to get the token.
    // For now, we simulate getting a token and passing it to the repository.
    final result = await _repository.socialLogin(provider, 'mock_oauth_token');
    if (result.isSuccess) {
      state = AuthState.authenticated;
    } else {
      state = AuthState.error;
    }
  }

  Future<void> guestLogin() async {
    state = AuthState.loading;
    final result = await _repository.guestLogin();
    if (result.isSuccess) {
      state = AuthState.authenticated;
    } else {
      state = AuthState.error;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState.unauthenticated;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
