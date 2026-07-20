import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/briefing_model.dart';
import '../services/home_repository.dart';

final briefingProvider = FutureProvider<BriefingModel>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  final response = await repository.getBriefing();
  if (response.isSuccess && response.data != null) {
    return response.data!;
  } else {
    throw Exception(response.message ?? 'Failed to load briefing');
  }
});
