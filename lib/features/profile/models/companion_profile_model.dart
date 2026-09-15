import 'package:freezed_annotation/freezed_annotation.dart';

part 'companion_profile_model.freezed.dart';
part 'companion_profile_model.g.dart';

enum CommunicationStyle { direct, reflective, encouraging, academic }
enum ProactivityLevel { reactive, balanced, proactive }

@freezed
abstract class CompanionProfileModel with _$CompanionProfileModel {
  const factory CompanionProfileModel({
    @Default(CommunicationStyle.reflective) CommunicationStyle communicationStyle,
    @Default(ProactivityLevel.balanced) ProactivityLevel proactivityLevel,
    @Default(true) bool requirePermissionForPlanner,
    @Default(true) bool memoryTransparencyEnabled,
    @Default(true) bool dailyBriefingEnabled,
  }) = _CompanionProfileModel;

  factory CompanionProfileModel.fromJson(Map<String, dynamic> json) => _$CompanionProfileModelFromJson(json);
}
