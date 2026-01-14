import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Web Fallback Storage
  final List<Map<String, dynamic>> _webSessions = [];
  final List<Map<String, dynamic>> _webMessages = [];
  final List<Map<String, dynamic>> _webPersonas = [];
  final List<Map<String, dynamic>> _webSavedApis = [];
  final List<Map<String, dynamic>> _webKnowledgeBase = [];

  DatabaseHelper._init();

  Future<Database> get database async {
    if (kIsWeb) {
      throw Exception("Web does not support SQLite. Use in-memory fallback.");
    }
    if (_database != null) return _database!;
    _database = await _initDB('pocket_mind.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) return Future.error("Not supported on web");
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path,
        version: 6, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE sessions ( 
  id $idType, 
  title $textType,
  created_at $intType,
  supabase_id TEXT,
  is_synced INTEGER DEFAULT 0
  )
''');

    await db.execute('''
CREATE TABLE messages ( 
  id $idType, 
  session_id $intType,
  role $textType,
  content $textType,
  timestamp $intType,
  supabase_id TEXT,
  is_synced INTEGER DEFAULT 0
  )
''');

    await db.execute('''
CREATE TABLE knowledge_base ( 
  id $idType, 
  title $textType,
  content $textType,
  timestamp $intType,
  embedding TEXT
  )
''');

    await db.execute('''
CREATE TABLE personas ( 
  id $idType, 
  name $textType,
  description $textType,
  prompt $textType
  )
''');

    await db.execute('''
CREATE TABLE saved_apis ( 
  id $idType, 
  name $textType,
  base_url $textType,
  model $textType,
  custom_body $textType
  )
'''); // New Table for BYOAPI
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    if (oldVersion < 2) {
      await db.execute('''
CREATE TABLE knowledge_base ( 
  id $idType, 
  title $textType,
  content $textType,
  timestamp $intType
  )
''');
    }

    if (oldVersion < 3) {
      await db.execute('''
CREATE TABLE personas ( 
  id $idType, 
  name $textType,
  description $textType,
  prompt $textType
  )
''');
    }

    if (oldVersion < 4) {
      await db.execute('''
CREATE TABLE saved_apis ( 
  id $idType, 
  name $textType,
  base_url $textType,
  model $textType,
  custom_body $textType
  )
''');
    }

    if (oldVersion < 5) {
      // Offline Sync Migration
      await db.execute('ALTER TABLE sessions ADD COLUMN supabase_id TEXT');
      await db.execute(
          'ALTER TABLE sessions ADD COLUMN is_synced INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE messages ADD COLUMN supabase_id TEXT');
      await db.execute(
          'ALTER TABLE messages ADD COLUMN is_synced INTEGER DEFAULT 0');
    }

    if (oldVersion < 6) {
      // RAG Embeddings Migration
      await db.execute('ALTER TABLE knowledge_base ADD COLUMN embedding TEXT');
    }
  }

  // SESSIONS
  Future<int> createSession(String title) async {
    final doc = {
      'title': title,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'is_synced': 0,
      'supabase_id': null,
    };

    if (kIsWeb) {
      doc['id'] = _webSessions.length + 1;
      _webSessions.add(doc);
      return doc['id'] as int;
    }

    final db = await database;
    final id = await db.insert('sessions', doc);
    return id;
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    if (kIsWeb) {
      return List.from(_webSessions.reversed);
    }
    final db = await database;
    return await db.query('sessions', orderBy: 'created_at DESC');
  }

  Future<int> deleteSession(int id) async {
    if (kIsWeb) {
      _webMessages.removeWhere((m) => m['session_id'] == id);
      _webSessions.removeWhere((s) => s['id'] == id);
      return 1;
    }
    final db = await database;
    await db.delete('messages', where: 'session_id = ?', whereArgs: [id]);
    return await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateSessionTitle(int id, String newTitle) async {
    if (kIsWeb) {
      final index = _webSessions.indexWhere((s) => s['id'] == id);
      if (index != -1) {
        _webSessions[index]['title'] = newTitle;
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.update(
      'sessions',
      {'title': newTitle},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // MESSAGES
  Future<int> createMessage(int sessionId, String role, String content) async {
    final doc = {
      'session_id': sessionId,
      'role': role,
      'content': content,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'is_synced': 0,
      'supabase_id': null,
    };

    if (kIsWeb) {
      doc['id'] = _webMessages.length + 1;
      _webMessages.add(doc);
      return doc['id'] as int;
    }

    final db = await database;
    return await db.insert('messages', doc);
  }

  Future<List<Map<String, dynamic>>> getMessages(
    int sessionId, {
    int? limit,
    int? offset,
  }) async {
    if (kIsWeb) {
      final filtered =
          _webMessages.where((m) => m['session_id'] == sessionId).toList();
      if (limit != null) {
        final startIndex = offset ?? 0;
        final endIndex = (startIndex + limit).clamp(0, filtered.length);
        return filtered.sublist(startIndex, endIndex);
      }
      return filtered;
    }
    final db = await database;
    return await db.query(
      'messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
      limit: limit,
      offset: offset,
    );
  }

  // PERSONAS
  Future<int> createPersona(
      String name, String description, String prompt) async {
    final Map<String, dynamic> doc = {
      'name': name,
      'description': description,
      'prompt': prompt,
    };
    if (kIsWeb) {
      doc['id'] = _webPersonas.length + 1;
      _webPersonas.add(doc);
      return doc['id'] as int;
    }
    final db = await database;
    return await db.insert('personas', doc);
  }

  Future<List<Map<String, dynamic>>> getPersonas() async {
    if (kIsWeb) return _webPersonas;
    final db = await database;
    return await db.query('personas');
  }

  Future<int> deletePersona(int id) async {
    if (kIsWeb) {
      _webPersonas.removeWhere((p) => p['id'] == id);
      return 1;
    }
    final db = await database;
    return await db.delete('personas', where: 'id = ?', whereArgs: [id]);
  }

  // SAVED APIs (BYOAPI)
  Future<int> createSavedApi(
      String name, String baseUrl, String model, String customBody) async {
    final Map<String, dynamic> doc = {
      'name': name,
      'base_url': baseUrl,
      'model': model,
      'custom_body': customBody,
    };
    if (kIsWeb) {
      doc['id'] = _webSavedApis.length + 1;
      _webSavedApis.add(doc);
      return doc['id'] as int;
    }
    final db = await database;
    return await db.insert('saved_apis', doc);
  }

  Future<List<Map<String, dynamic>>> getSavedApis() async {
    if (kIsWeb) return _webSavedApis;
    final db = await database;
    return await db.query('saved_apis');
  }

  Future<int> deleteSavedApi(int id) async {
    if (kIsWeb) {
      _webSavedApis.removeWhere((a) => a['id'] == id);
      return 1;
    }
    final db = await database;
    return await db.delete('saved_apis', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedSessions() async {
    if (kIsWeb) return _webSessions.where((s) => s['is_synced'] == 0).toList();
    final db = await database;
    return await db.query('sessions', where: 'is_synced = 0');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedMessages() async {
    if (kIsWeb) return _webMessages.where((m) => m['is_synced'] == 0).toList();
    final db = await database;
    return await db.query('messages', where: 'is_synced = 0');
  }

  Future<void> markSessionSynced(int id, String supabaseId) async {
    if (kIsWeb) {
      final index = _webSessions.indexWhere((s) => s['id'] == id);
      if (index != -1) {
        _webSessions[index]['is_synced'] = 1;
        _webSessions[index]['supabase_id'] = supabaseId;
      }
      return;
    }
    final db = await database;
    await db.update('sessions', {'is_synced': 1, 'supabase_id': supabaseId},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markMessageSynced(int id, String supabaseId) async {
    if (kIsWeb) {
      final index = _webMessages.indexWhere((m) => m['id'] == id);
      if (index != -1) {
        _webMessages[index]['is_synced'] = 1;
        _webMessages[index]['supabase_id'] = supabaseId;
      }
      return;
    }
    final db = await database;
    await db.update('messages', {'is_synced': 1, 'supabase_id': supabaseId},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getSessionById(int id) async {
    if (kIsWeb) {
      try {
        return _webSessions.firstWhere((s) => s['id'] == id);
      } catch (e) {
        return null;
      }
    }
    final db = await database;
    final results =
        await db.query('sessions', where: 'id = ?', whereArgs: [id]);
    if (results.isNotEmpty) return results.first;
    return null;
  }

  // KNOWLEDGE BASE (De-Mocking & Web Fallback)
  Future<int> createKnowledge(String title, String content,
      {List<double>? embedding}) async {
    final Map<String, dynamic> doc = {
      'title': title,
      'content': content,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'embedding': embedding?.toString(),
    };
    if (kIsWeb) {
      doc['id'] = _webKnowledgeBase.length + 1;
      _webKnowledgeBase.add(doc);
      return doc['id'] as int;
    }
    final db = await database;
    return await db.insert('knowledge_base', doc);
  }

  Future<List<Map<String, dynamic>>> getKnowledge() async {
    if (kIsWeb) return List.from(_webKnowledgeBase.reversed);
    final db = await database;
    return await db.query('knowledge_base', orderBy: 'timestamp DESC');
  }

  // Simple Keyword Search
  Future<List<Map<String, dynamic>>> searchKnowledge(String query) async {
    if (kIsWeb) {
      return _webKnowledgeBase
          .where((k) => (k['content'] as String).contains(query))
          .take(3)
          .toList();
    }
    final db = await database;
    return await db.query(
      'knowledge_base',
      where: 'content LIKE ?',
      whereArgs: ['%${query.trim()}%'],
      limit: 3,
    );
  }

  Future<void> clearKnowledge() async {
    if (kIsWeb) {
      _webKnowledgeBase.clear();
      return;
    }
    final db = await database;
    await db.delete('knowledge_base');
  }
}
