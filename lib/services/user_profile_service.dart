import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class UserProfileService {
  static final UserProfileService instance = UserProfileService._init();
  static Database? _database;

  UserProfileService._init();

  Future<Database> get database async {
    if (kIsWeb) {
      throw Exception("Web does not support SQLite");
    }
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'user_profile.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE user_profile (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT UNIQUE NOT NULL,
            display_name TEXT NOT NULL,
            profile_picture_path TEXT,
            theme_preference TEXT DEFAULT 'dark',
            default_ai_mode TEXT DEFAULT 'network',
            default_persona_id INTEGER,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // Create or update user profile
  Future<int> saveProfile({
    required String userId,
    required String displayName,
    String? profilePicturePath,
    String? themePreference,
    String? defaultAIMode,
    int? defaultPersonaId,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final data = {
      'user_id': userId,
      'display_name': displayName,
      'profile_picture_path': profilePicturePath,
      'theme_preference': themePreference ?? 'dark',
      'default_ai_mode': defaultAIMode ?? 'network',
      'default_persona_id': defaultPersonaId,
      'updated_at': now,
    };

    // Try to update first
    final existing = await getProfile(userId);

    if (existing == null) {
      // Create new
      data['created_at'] = now;
      return await db.insert('user_profile', data);
    } else {
      // Update existing
      return await db.update(
        'user_profile',
        data,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final db = await database;
    final results = await db.query(
      'user_profile',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  // Update display name only
  Future<void> updateDisplayName(String userId, String newName) async {
    await saveProfile(
      userId: userId,
      displayName: newName,
    );
  }

  // Update profile picture path
  Future<void> updateProfilePicture(String userId, String picturePath) async {
    final db = await database;
    await db.update(
      'user_profile',
      {
        'profile_picture_path': picturePath,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
