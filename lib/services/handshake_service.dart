import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'app_config.dart';

class HandshakeService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<bool> performHandshake(String qrData) async {
    try {
      // User scans User ID directly from React Dashboard
      // Check if it's JSON or just a String (User ID)
      String userId = qrData.trim();
      if (userId.startsWith('{')) {
        try {
          final data = jsonDecode(userId);
          userId = data['user_id'] ?? data['id'] ?? userId;
        } catch (e) {}
      }

      print('Scanning for User ID: $userId');

      // 1. Query Supabase for Bridge IP
      final response = await supabase
          .from('users')
          .select('last_bridge_ip')
          .eq('auth_id', userId)
          .maybeSingle();

      if (response == null || response['last_bridge_ip'] == null) {
        print("No Bridge IP found for this user.");
        return false;
      }

      final ip = response['last_bridge_ip'];
      final url = "http://$ip:8000";

      // 2. Verify Connection
      final pong = await http
          .get(Uri.parse('$url/debug'))
          .timeout(const Duration(seconds: 3));
      if (pong.statusCode != 200) throw Exception("Bridge Unreachable");

      // 3. Update Local Config
      AppConfig.bridgeUrl = url;

      // 4. Save to Supabase (Optional: Persistence)
      // The requirement says "Saves it to the api_configs table"
      await _saveToApiConfigs(userId, url);

      return true;
    } catch (e) {
      print("Handshake Failed: $e");
      return false;
    }
  }

  Future<void> _saveToApiConfigs(String userId, String url) async {
    // Save as 'Ollama' provider config?
    // User requirement: "under the 'Ollama' provider"
    try {
      await supabase.from('api_configs').upsert({
        'user_id': userId,
        'provider': 'Ollama',
        'base_url': url,
        'model': 'llama3', // Default
        'api_key': 'none'
      });
    } catch (e) {
      print("Config Save Error: $e");
    }
  }

  Future<void> syncFromSupabase() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('users')
          .select('last_bridge_ip')
          .eq('auth_id', user.id)
          .maybeSingle();

      if (response != null && response['last_bridge_ip'] != null) {
        // Construct URL from IP
        AppConfig.bridgeUrl = "http://${response['last_bridge_ip']}:8000";
        print("Synced Bridge URL from cloud: ${AppConfig.bridgeUrl}");
      }
    } catch (e) {
      print("Sync Check Failed: $e");
    }
  }
}
