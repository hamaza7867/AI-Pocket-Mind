import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // ✅ SECURE: Load from environment variables
  // Keys are now stored in .env file (gitignored for security)

  static String bridgeUrl = "http://127.0.0.1:8000"; // Dynamic Bridge URL

  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? _throwMissingEnv('SUPABASE_URL');

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? _throwMissingEnv('SUPABASE_ANON_KEY');

  static String get googleWebClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ??
      _throwMissingEnv('GOOGLE_WEB_CLIENT_ID');

  static String get tavilyApiKey =>
      dotenv.env['TAVILY_API_KEY'] ?? _throwMissingEnv('TAVILY_API_KEY');

  /// Throws error if required environment variable is missing
  static String _throwMissingEnv(String key) {
    throw Exception('❌ Missing required environment variable: $key\n'
        'Please ensure .env file exists and contains $key.\n'
        'Copy .env.example to .env and fill in your API keys.');
  }
}
