import 'package:flutter_test/flutter_test.dart';
import 'package:ai_pocket_mind/services/database_helper.dart';
import 'package:ai_pocket_mind/providers/chat_provider.dart';

void main() {
  group('Authentication Flow Tests', () {
    test('Session creation stores data correctly', () async {
      // Test session creation
      final sessionId = await DatabaseHelper.instance.createSession('Test Chat');
      
      expect(sessionId, isNotNull);
      expect(sessionId, greaterThan(0));
      
      // Verify session exists
      final sessions = await DatabaseHelper.instance.getSessions();
      expect(sessions, isNotEmpty);
      expect(sessions.any((s) => s['id'] == sessionId), isTrue);
    });

    test('Messages are stored in session', () async {
      // Create test session
      final sessionId = await DatabaseHelper.instance.createSession('Test Session');
      
      // Add test message
      await DatabaseHelper.instance.createMessage(
        sessionId,
        'user',
        'Hello test message',
      );
      
      // Retrieve messages
      final messages = await DatabaseHelper.instance.getMessages(sessionId);
      
      expect(messages, isNotEmpty);
      expect(messages.length, equals(1));
      expect(messages.first['content'], equals('Hello test message'));
      expect(messages.first['role'], equals('user'));
    });

    test('Session deletion removes all data', () async {
      // Create and then delete session
      final sessionId = await DatabaseHelper.instance.createSession('Delete Test');
      await DatabaseHelper.instance.createMessage(sessionId, 'user', 'Test');
      
      await DatabaseHelper.instance.deleteSession(sessionId);
      
      // Verify deletion
      final sessions = await DatabaseHelper.instance.getSessions();
      expect(sessions.any((s) => s['id'] == sessionId), isFalse);
      
      final messages = await DatabaseHelper.instance.getMessages(sessionId);
      expect(messages, isEmpty);
    });
  });

  group('Message Pagination Tests', () {
    late int testSessionId;

    setUp(() async {
      // Create session with multiple messages
      testSessionId = await DatabaseHelper.instance.createSession('Pagination Test');
      for (int i = 0; i < 100; i++) {
        await DatabaseHelper.instance.createMessage(
          testSessionId,
          i % 2 == 0 ? 'user' : 'assistant',
          'Test message $i',
        );
      }
    });

    test('Default pagination loads all messages', () async {
      final messages = await DatabaseHelper.instance.getMessages(testSessionId);
      expect(messages.length, equals(100));
    });

    test('Limit parameter restricts results', () async {
      final messages = await DatabaseHelper.instance.getMessages(
        testSessionId,
        limit: 50,
      );
      expect(messages.length, equals(50));
    });

    test('Offset parameter skips messages', () async {
      final messages = await DatabaseHelper.instance.getMessages(
        testSessionId,
        limit: 10,
        offset: 90,
      );
      expect(messages.length, equals(10));
      // Should get messages 90-99
      expect(messages.first['content'], contains('90'));
    });

    tearDown() async {
      // Clean up
      await DatabaseHelper.instance.deleteSession(testSessionId);
    });
  });

  group('Session Management Tests', () {
    test('Multiple sessions can coexist', () async {
      final session1 = await DatabaseHelper.instance.createSession('Session 1');
      final session2 = await DatabaseHelper.instance.createSession('Session 2');
      
      await DatabaseHelper.instance.createMessage(session1, 'user', 'Message in 1');
      await DatabaseHelper.instance.createMessage(session2, 'user', 'Message in 2');
      
      final msg1 = await DatabaseHelper.instance.getMessages(session1);
      final msg2 = await DatabaseHelper.instance.getMessages(session2);
      
      expect(msg1.length, equals(1));
      expect(msg2.length, equals(1));
      expect(msg1.first['content'], equals('Message in 1'));
      expect(msg2.first['content'], equals('Message in 2'));
      
      // Cleanup
      await DatabaseHelper.instance.deleteSession(session1);
      await DatabaseHelper.instance.deleteSession(session2);
    });

    test('Session title can be updated', () async {
      final sessionId = await DatabaseHelper.instance.createSession('Original Title');
      
      await DatabaseHelper.instance.updateSessionTitle(sessionId, 'Updated Title');
      
      final sessions = await DatabaseHelper.instance.getSessions();
      final session = sessions.firstWhere((s) => s['id'] == sessionId);
      
      expect(session['title'], equals('Updated Title'));
      
      // Cleanup
      await DatabaseHelper.instance.deleteSession(sessionId);
    });
  });
}
