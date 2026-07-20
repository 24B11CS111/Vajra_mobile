import 'entity.dart';

/// Represents a parsed intent from the user's input.
class Intent {
  final String name; // e.g., 'create_reminder', 'get_weather'
  final double confidence; // 0.0 to 1.0
  final List<Entity> entities;
  final bool isAmbiguous;
  final String? followUpQuestion; // Generated if ambiguous

  const Intent({
    required this.name,
    this.confidence = 1.0,
    this.entities = const [],
    this.isAmbiguous = false,
    this.followUpQuestion,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'confidence': confidence,
    'entities': entities.map((e) => e.toJson()).toList(),
    'isAmbiguous': isAmbiguous,
    'followUpQuestion': followUpQuestion,
  };

  factory Intent.fromJson(Map<String, dynamic> json) {
    return Intent(
      name: json['name'] as String,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      entities: (json['entities'] as List<dynamic>?)
          ?.map((e) => Entity.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      isAmbiguous: json['isAmbiguous'] as bool? ?? false,
      followUpQuestion: json['followUpQuestion'] as String?,
    );
  }
}
