import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/ai/services/tool_framework.dart';

class MockWeatherTool extends AiTool {
  @override
  String get name => 'get_weather';

  @override
  String get description => 'Get the current weather for a location.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'location': {
        'type': 'string',
        'description': 'The city name',
      }
    },
    'required': ['location'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    return {'temperature': 22, 'condition': 'Sunny'};
  }
}

void main() {
  group('ToolRegistry', () {
    late ToolRegistry registry;

    setUp(() {
      registry = ToolRegistry();
    });

    test('register and getTool works correctly', () {
      final tool = MockWeatherTool();
      registry.register(tool);
      
      final retrieved = registry.getTool('get_weather');
      expect(retrieved, isNotNull);
      expect(retrieved?.name, 'get_weather');
    });

    test('availableToolsSchema returns correct schema format', () {
      registry.register(MockWeatherTool());
      final schemas = registry.availableToolsSchema;
      
      expect(schemas.length, 1);
      expect(schemas.first['type'], 'function');
      expect(schemas.first['function']['name'], 'get_weather');
    });
  });
}
