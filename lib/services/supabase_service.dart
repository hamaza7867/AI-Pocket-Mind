import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io' show Platform;
import 'app_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;

  // Initialize with URL and Key
  Future<void> initialize(String url, String anonKey) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
    _client = Supabase.instance.client;
  }

  SupabaseClient get client {
    if (_client == null) {
      throw Exception("Supabase not initialized. Please configure Settings.");
    }
    return _client!;
  }

  // --- Auth ---
  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'io.supabase.flutterquickstart://login-callback',
    );
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await client.auth
        .signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<AuthResponse> signInWithGoogle() async {
    /// Web Client ID that you registered with Google Cloud.
    final webClientId = AppConfig.googleWebClientId;

    // 1. Trigger the authentication flow
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: Platform.isIOS
          ? AppConfig.googleWebClientId // Use webClientId for iOS
          : null, // Android uses google-services.json
      serverClientId: webClientId,
      scopes: ['email'],
    );
    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser!.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw 'No ID Token found.';
    }

    return await client.auth.signInWithIdToken(
      provider: Provider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  // --- Database Methods (Users) ---
  Future<void> createUserProfile(
      String fullName, String email, String studentId) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    // Note: The SQL trigger 'on_auth_user_created' usually handles creation.
    // This function is now treated as an "Update Profile" or "Ensure Exists" fallback.

    // Check if exists
    final existing = await client
        .from('users')
        .select()
        .eq('auth_id', user.id)
        .maybeSingle();

    if (existing == null) {
      // Validation: Insert if not exists (simulating the trigger manually if needed)
      // using 'auth_id' instead of 'user_id' which is now auto-increment integer
      await client.from('users').insert({
        'auth_id': user.id,
        'full_name': fullName,
        'email': email,
        'student_id': studentId,
        // 'created_at': defaults to now()
      });
    } else {
      // Update existing
      await client.from('users').update({
        'full_name': fullName,
        'email': email,
        'student_id': studentId,
      }).eq('auth_id', user.id);
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    try {
      // Query by auth_id, not user_id
      final response =
          await client.from('users').select().eq('auth_id', user.id).single();
      return response;
    } catch (e) {
      return null;
    }
  }

  // Helper to get the Internal DB Integer ID from Auth UUID
  Future<int> _getInternalUserId() async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final response = await client
        .from('users')
        .select('user_id')
        .eq('auth_id', user.id)
        .maybeSingle();

    if (response == null) {
      // If user missing from public table (failed trigger?), try to create basic record
      await createUserProfile(user.userMetadata?['full_name'] ?? "User",
          user.email ?? "", "ST-000");
      // Retry
      final retry = await client
          .from('users')
          .select('user_id')
          .eq('auth_id', user.id)
          .single();
      return retry['user_id'] as int;
    }
    return response['user_id'] as int;
  }

  // --- Database Methods (Sessions) ---
  Future<List<Map<String, dynamic>>> getSessions() async {
    final user = client.auth.currentUser;
    if (user == null) return [];

    // The RLS policy 'Users manage own sessions' filters by auth.uid() automatically.
    // However, explicitly filtering is good practice.
    // We can filter by the integer user_id.

    try {
      final int userId = await _getInternalUserId();

      final response = await client
          .from('chat_sessions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<int> createSession(String title, int? personaId) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final int userId = await _getInternalUserId();

    final response = await client.from('chat_sessions').insert({
      'user_id': userId, // Integer FK
      'persona_id': personaId,
      'session_title': title,
    }).select();

    return response[0]['session_id'] as int;
  }

  // --- Database Methods (Messages) ---
  Future<void> saveMessage(int sessionId, String role, String content) async {
    await client.from('messages').insert({
      'session_id': sessionId,
      'sender_role': role,
      'content': content,
    });
  }

  Future<List<Map<String, dynamic>>> getMessages(int sessionId) async {
    final response = await client
        .from('messages')
        .select()
        .eq('session_id', sessionId)
        .order('msg_time', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // --- Database Methods (API Configs) ---
  Future<void> saveApiConfig({
    required String provider,
    required String apiKey,
    required String baseUrl,
    String? model,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    final userId = await _getInternalUserId();

    // Upsert based on user_id and provider?
    // Usually we want one config per provider or just ONE active config?
    // Let's assume one active config per provider, or just a table.
    // Schema: api_id, user_id, provider, base_url, api_key.

    // Check if exists
    final existing = await client
        .from('api_configs')
        .select()
        .eq('user_id', userId)
        .eq('provider', provider)
        .maybeSingle();

    if (existing != null) {
      await client.from('api_configs').update({
        'api_key': apiKey,
        'base_url': baseUrl,
        // 'model': model, // If you add model column later
      }).eq('api_id', existing['api_id']);
    } else {
      await client.from('api_configs').insert({
        'user_id': userId,
        'provider': provider,
        'api_key': apiKey,
        'base_url': baseUrl,
      });
    }
  }

  Future<Map<String, dynamic>?> getApiConfig(String provider) async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    try {
      final userId = await _getInternalUserId();
      final response = await client
          .from('api_configs')
          .select()
          .eq('user_id', userId)
          .eq('provider', provider)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllApiConfigs() async {
    final user = client.auth.currentUser;
    if (user == null) return [];
    try {
      final userId = await _getInternalUserId();
      final response =
          await client.from('api_configs').select().eq('user_id', userId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}
