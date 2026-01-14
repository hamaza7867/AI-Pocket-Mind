import 'package:flutter_test/flutter_test.dart';
import 'package:ai_pocket_mind/services/tools_service.dart';
import 'package:ai_pocket_mind/services/api_registry.dart';

// Mock AppConfig if needed, but since it's a static const class in lib,
// we can usually rely on it if the file exists.
// However, network calls in tests might be flaky or blocked in some CI envs.
// We will try to make real calls to verify endpoints are valid.

void main() {
  group('ToolsService Verification', () {
    late ToolsService toolsService;

    setUp(() {
      toolsService = ToolsService();
      // Use it to silence lint
      expect(toolsService, isNotNull);
    });

    test('Registry contains expected providers', () {
      expect(ApiRegistry.providers.containsKey('finance_rate'), true);
      expect(ApiRegistry.providers.containsKey('find_book'), true);
      expect(ApiRegistry.providers.containsKey('meal_recipe'), true);
      expect(ApiRegistry.providers.containsKey('dicebear'), true);
    });

    // We can't easily test "tavily_search" without making a real HTTP call,
    // which is bad practice for unit tests but acceptable for a "verification script".
    // However, `flutter test` might block external network access depending on config.
    // Let's rely on basic logic checks and registry integrity first.

    test('ApiRegistry URL generation logic', () {
      final config = ApiRegistry.providers['finance_rate']!;
      final url = config.urlTemplate.replaceAll('{query}', 'USD');
      expect(url, 'https://api.exchangerate-api.com/v4/latest/USD');
    });

    test('Avatar URL generation', () {
      final config = ApiRegistry.providers['dicebear']!;
      final url = config.urlTemplate.replaceAll('{query}', 'Alice');
      expect(url, 'https://api.dicebear.com/7.x/pixel-art/svg?seed=Alice');
    });
  });
}
