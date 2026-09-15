import 'package:freezed_annotation/freezed_annotation.dart';

part 'memory_model.freezed.dart';
part 'memory_model.g.dart';

@freezed
abstract class MemoryModel with _$MemoryModel {
  const factory MemoryModel({
    required String id,
    required String content,
    required String category,
    required double importanceScore,
    required bool isPinned,
    required DateTime createdAt,
    @Default('VAJRA Core') String source,
  }) = _MemoryModel;

  factory MemoryModel.fromJson(Map<String, dynamic> json) => _$MemoryModelFromJson(json);
}
