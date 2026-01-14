import 'package:flutter/foundation.dart';
import 'database_helper.dart';
import 'supabase_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  bool _isSyncing = false;

  Future<void> syncPendingData() async {
    if (_isSyncing) return;

    // Simple checks for connectivity
    // Note: connectivity_plus check is good practice but optional if we just handle errors
    // final connectivityResult = await (Connectivity().checkConnectivity());
    // if (connectivityResult == ConnectivityResult.none) return;

    _isSyncing = true;
    try {
      debugPrint("SyncService: Starting sync...");
      await _syncSessions();
      await _syncMessages();
      debugPrint("SyncService: Sync complete.");
    } catch (e) {
      debugPrint("SyncService: Error during sync: $e");
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncSessions() async {
    final unsyncedSessions =
        await DatabaseHelper.instance.getUnsyncedSessions();

    for (var session in unsyncedSessions) {
      try {
        final localId = session['id'];
        final title = session['title'];

        // Upload to Supabase
        // We need a method in SupabaseService to insert and return ID
        final supabaseId = await SupabaseService()
            .createSession(title, null); // personaId null for now

        // Update Local DB
        await DatabaseHelper.instance
            .markSessionSynced(localId, supabaseId.toString());
      } catch (e) {
        debugPrint("SyncService: Failed to sync session ${session['id']}: $e");
      }
    }
  }

  Future<void> _syncMessages() async {
    final unsyncedMessages =
        await DatabaseHelper.instance.getUnsyncedMessages();

    // Group by session to optimize? Or just one by one for safety.
    // Need to make sure the session is synced first!

    for (var msg in unsyncedMessages) {
      try {
        final localId = msg['id'];
        final localSessionId = msg['session_id'];

        // Check if the session has a supabase_id
        final session =
            await DatabaseHelper.instance.getSessionById(localSessionId);
        if (session == null) continue; // Should not happen

        String? supabaseSessionId = session['supabase_id'];

        if (supabaseSessionId == null) {
          // Warning: Session not synced yet. Skip message for now.
          // The next pass of _syncSessions should fix this, then next pass of _syncMessages works.
          continue;
        }

        // Upload
        await SupabaseService().saveMessage(
            int.parse(supabaseSessionId), // Assuming Supabase ID is int
            msg['role'],
            msg['content']);

        // Update Local
        await DatabaseHelper.instance.markMessageSynced(localId, "synced");
      } catch (e) {
        debugPrint("SyncService: Failed to sync message ${msg['id']}: $e");
      }
    }
  }
}
