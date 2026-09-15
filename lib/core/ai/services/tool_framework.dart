/// Represents a tool that the AI can call.
abstract class AiTool {
  /// The unique identifier of the tool (must match the model's expected function name).
  String get name;

  /// A detailed description of what this tool does and when the AI should use it.
  String get description;

  /// The JSON schema representing the expected input parameters.
  Map<String, dynamic> get inputSchema;

  /// Validates the provided input against the schema before execution.
  bool validate(Map<String, dynamic> input) {
    // In a real implementation, perform JSON schema validation here.
    return true;
  }

  /// Executes the tool with the given input and returns the result.
  Future<dynamic> execute(Map<String, dynamic> input);
}

/// A registry to hold and manage all available AI tools.
class ToolRegistry {
  final Map<String, AiTool> _tools = {};

  void register(AiTool tool) {
    _tools[tool.name] = tool;
  }

  AiTool? getTool(String name) {
    return _tools[name];
  }

  List<Map<String, dynamic>> get availableToolsSchema {
    return _tools.values.map((tool) => {
      'type': 'function',
      'function': {
        'name': tool.name,
        'description': tool.description,
        'parameters': tool.inputSchema,
      }
    }).toList();
  }
}
