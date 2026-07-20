import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile_model.dart';
import '../models/companion_profile_model.dart';
import '../services/profile_repository.dart';

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfileModel>> {
  final ProfileRepository _repository;

  ProfileNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await _repository.getUserProfile();
      if (response.isSuccess && response.data != null) {
        state = AsyncValue.data(response.data!);
      } else {
        state = AsyncValue.error(response.message ?? 'Failed to load user profile', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfileModel>>((ref) {
  return ProfileNotifier(ref.watch(profileRepositoryProvider));
});

class CompanionProfileNotifier extends StateNotifier<CompanionProfileModel> {
  final ProfileRepository _repository;

  CompanionProfileNotifier(this._repository) : super(const CompanionProfileModel()) {
    _loadCompanionProfile();
  }

  Future<void> _loadCompanionProfile() async {
    try {
      final response = await _repository.getCompanionProfile();
      if (response.isSuccess && response.data != null) {
        state = response.data!;
      }
    } catch (_) {}
  }

  Future<void> updateStyle(CommunicationStyle style) async {
    final newState = state.copyWith(communicationStyle: style);
    state = newState;
    await _repository.updateCompanionProfile(newState);
  }

  Future<void> updateProactivity(ProactivityLevel level) async {
    final newState = state.copyWith(proactivityLevel: level);
    state = newState;
    await _repository.updateCompanionProfile(newState);
  }

  Future<void> togglePermission(bool val) async {
    final newState = state.copyWith(requirePermissionForPlanner: val);
    state = newState;
    await _repository.updateCompanionProfile(newState);
  }

  Future<void> toggleMemoryTransparency(bool val) async {
    final newState = state.copyWith(memoryTransparencyEnabled: val);
    state = newState;
    await _repository.updateCompanionProfile(newState);
  }
}

final companionProfileProvider = StateNotifierProvider<CompanionProfileNotifier, CompanionProfileModel>((ref) {
  return CompanionProfileNotifier(ref.watch(profileRepositoryProvider));
});
