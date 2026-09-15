// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MemoryModel _$MemoryModelFromJson(Map<String, dynamic> json) => _MemoryModel(
  id: json['id'] as String,
  content: json['content'] as String,
  category: json['category'] as String,
  importanceScore: (json['importanceScore'] as num).toDouble(),
  isPinned: json['isPinned'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  source: json['source'] as String? ?? 'VAJRA Core',
);

Map<String, dynamic> _$MemoryModelToJson(_MemoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'category': instance.category,
      'importanceScore': instance.importanceScore,
      'isPinned': instance.isPinned,
      'createdAt': instance.createdAt.toIso8601String(),
      'source': instance.source,
    };
