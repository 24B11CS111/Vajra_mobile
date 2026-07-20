/// Represents an extracted entity from the user's input.
class Entity {
  final String type; // e.g., 'date', 'time', 'task', 'location'
  final String value; // e.g., 'tomorrow', 'morning', 'call mom', 'New York'
  final double confidence; // 0.0 to 1.0

  const Entity({
    required this.type,
    required this.value,
    this.confidence = 1.0,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'value': value,
    'confidence': confidence,
  };

  factory Entity.fromJson(Map<String, dynamic> json) {
    return Entity(
      type: json['type'] as String,
      value: json['value'] as String,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
