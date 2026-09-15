// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'companion_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CompanionProfileModel _$CompanionProfileModelFromJson(
  Map<String, dynamic> json,
) => _CompanionProfileModel(
  communicationStyle:
      $enumDecodeNullable(
        _$CommunicationStyleEnumMap,
        json['communicationStyle'],
      ) ??
      CommunicationStyle.reflective,
  proactivityLevel:
      $enumDecodeNullable(
        _$ProactivityLevelEnumMap,
        json['proactivityLevel'],
      ) ??
      ProactivityLevel.balanced,
  requirePermissionForPlanner:
      json['requirePermissionForPlanner'] as bool? ?? true,
  memoryTransparencyEnabled: json['memoryTransparencyEnabled'] as bool? ?? true,
  dailyBriefingEnabled: json['dailyBriefingEnabled'] as bool? ?? true,
);

Map<String, dynamic> _$CompanionProfileModelToJson(
  _CompanionProfileModel instance,
) => <String, dynamic>{
  'communicationStyle':
      _$CommunicationStyleEnumMap[instance.communicationStyle]!,
  'proactivityLevel': _$ProactivityLevelEnumMap[instance.proactivityLevel]!,
  'requirePermissionForPlanner': instance.requirePermissionForPlanner,
  'memoryTransparencyEnabled': instance.memoryTransparencyEnabled,
  'dailyBriefingEnabled': instance.dailyBriefingEnabled,
};

const _$CommunicationStyleEnumMap = {
  CommunicationStyle.direct: 'direct',
  CommunicationStyle.reflective: 'reflective',
  CommunicationStyle.encouraging: 'encouraging',
  CommunicationStyle.academic: 'academic',
};

const _$ProactivityLevelEnumMap = {
  ProactivityLevel.reactive: 'reactive',
  ProactivityLevel.balanced: 'balanced',
  ProactivityLevel.proactive: 'proactive',
};
