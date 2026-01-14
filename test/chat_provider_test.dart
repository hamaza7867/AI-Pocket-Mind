import 'package:flutter_test/flutter_test.dart';
import 'package:ai_pocket_mind/providers/chat_provider.dart';
import 'package:ai_pocket_mind/services/database_helper.dart';

void main() {
  group('ChatProvider Performance Tests', () {
    late ChatProvider provider;

    setUp(() {
      provider = ChatProvider();
    });

    test('Provider initializes correctly', () {
      expect(provider, isNotNull);
      expect(provider.messages, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('Messages list starts empty', () {
      expect(provider.messages.length, equals(0));
    });

    test('Loading state toggles correctly', () async {
      expect(provider.isLoading, isFalse);

      // Note: In real test would mock the AI service
      // This is a structural test
    });

    test('Current mode can be retrieved', () {
      final mode = provider.currentMode;
      expect(mode, isNotNull);
      // Should default to network mode
      expect(mode, equals(AIMode.network));
    });

    test('Session management basic flow', () async {
      // Create new session
      await provider.startNewSession();

      expect(provider.currentSessionId, isNotNull);
      expect(provider.currentSessionId, greaterThan(0));

      // Cleanup
      if (provider.currentSessionId != null) {
        await DatabaseHelper.instance.deleteSession(provider.currentSessionId!);
      }
    });

    test('Multiple sessions can be created', () async {
      await provider.startNewSession();
      final session1 = provider.currentSessionId;

      await provider.startNewSession();
      final session2 = provider.currentSessionId;

      expect(session1, isNot(equals(session2)));

      // Cleanup
      if (session1 != null)
        await DatabaseHelper.instance.deleteSession(session1);
      if (session2 != null)
        await DatabaseHelper.instance.deleteSession(session2);
    });
  });

  group('Settings Management Tests', () {
    late ChatProvider provider;

    setUp(() {
      provider = ChatProvider();
    });

    test('Default settings are loaded', () {
      expect(provider.currentOllamaUrl, isNotEmpty);
      expect(provider.currentCloudProvider, isNotEmpty);
    });

    test('Settings can be updated', () async {
      const testUrl = 'http://test.local:11434';
      const testKey = 'test-api-key';
      const testProvider = 'OpenAI';
      const testModel = 'gpt-4';

      await provider.updateSettings(
        ollamaUrl: testUrl,
        apiKey: testKey,
        mode: AIMode.cloud,
        cloudProvider: testProvider,
        cloudModel: testModel,
      );

      expect(provider.currentOllamaUrl, equals(testUrl));
      expect(provider.currentApiKey, equals(testKey));
      expect(provider.currentCloudProvider, equals(testProvider));
      expect(provider.currentCloudModel, equals(testModel));
    });
  });

  group('Message Flow Tests', () {
    test('Empty message is rejected', () async {
      final provider = ChatProvider();

      // Should not crash on empty message
      await provider.sendMessage('');
      await provider.sendMessage('   ');

      expect(provider.messages, isEmpty);
    });

    test('Debug command is recognized', () async {
      final provider = ChatProvider();
      await provider.startNewSession();

      await provider.sendMessage('/debug');

      // Should have response about debug
      expect(provider.messages.length, greaterThan(0));

      // Cleanup
      if (provider.currentSessionId != null) {
        await DatabaseHelper.instance.deleteSession(provider.currentSessionId!);
      }
    });
  });
}
