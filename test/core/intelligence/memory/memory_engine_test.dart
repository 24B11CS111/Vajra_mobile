import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/intelligence/memory/memory_engine.dart';

void main() {
  group('MemoryEngine', () {
    late MemoryEngine engine;

    setUp(() {
      engine = MemoryEngine();
    });

    test('remember adds a memory', () async {
      await engine.remember('test memory');
      expect(engine.state.recentMemories.length, 1);
      expect(engine.state.recentMemories.first.content, 'test memory');
    });

    test('delete removes a memory', () async {
      await engine.remember('test memory');
      final id = engine.state.recentMemories.first.id;
      await engine.delete(id);
      expect(engine.state.recentMemories, isEmpty);
    });

    test('pin updates pinned status', () async {
      await engine.remember('test memory');
      final id = engine.state.recentMemories.first.id;
      await engine.pin(id, true);
      expect(engine.state.recentMemories.first.isPinned, isTrue);
    });
  });
}
