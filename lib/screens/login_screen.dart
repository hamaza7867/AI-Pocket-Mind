import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../services/supabase_service.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/chat_provider.dart'; // Added Import
import '../utils/theme_utils.dart'; // Restored
import 'chat_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isSignUp = false;

  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    // Listen for Auth Changes (e.g. Deep Link Click)
    _authSubscription =
        SupabaseService().client.auth.onAuthStateChange.listen((data) {
      if (data.session != null && mounted) {
        _handleLoginSuccess(context, navigate: true);
      }
    });
  }

  // Unified Success Handler with Auto-Fetch
  Future<void> _handleLoginSuccess(BuildContext context,
      {bool navigate = true}) async {
    // 1. Auto-Fetch API Configs
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    try {
      final apis = await SupabaseService().getAllApiConfigs();
      if (apis.isNotEmpty) {
        final config = apis.first; // Load first available
        // debugPrint("Auto-Fetching Cloud Config: ${config['provider']}");

        chatProvider.updateSettings(
          mode: AIMode.byoapi,
          desktopBridgeUrl: chatProvider.currentDesktopUrl,
          apiKey: config['api_key'] ?? "",
          cloudProvider: config['provider'] ?? "OpenAI",
          cloudModel: chatProvider.currentCloudModel, // Default
          customBaseUrl: config['base_url'] ?? "",
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ Synced AI Settings for ${config['provider']}"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Auto-Fetch Error: $e");
    }

    // 2. Navigate
    if (navigate && mounted) {
      // Check if already on ChatScreen to avoid dupes?
      // LoginScreen is usually replaced.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final response = await SupabaseService().signInWithGoogle();
      if (response.user != null && mounted) {
        // Successful login
        await _handleLoginSuccess(context, navigate: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      AuthResponse response;
      if (_isSignUp) {
        response = await SupabaseService().signUpWithEmail(email, password);
        if (response.user != null) {
          // Optional: Create profile immediately
          await SupabaseService()
              .createUserProfile("New User", email, "000000");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account Created! Welcome.')),
            );
          }
        }
      } else {
        response = await SupabaseService().signInWithEmail(email, password);
      }

      if (response.user != null && response.session != null) {
        // Logged in successfully
        if (mounted) {
          await _handleLoginSuccess(context, navigate: true);
        }
      } else if (response.user != null && response.session == null) {
        // Awaiting email verification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Verification email sent! Please check your inbox and click the link to login.'),
              duration: Duration(seconds: 5),
            ),
          );
          // Do not navigate yet. The deep link will bring them back.
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      backgroundColor: FuturisticTheme.getBackgroundColor(isDark),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: FuturisticTheme.getBackgroundGradient(isDark),
              ),
            ),
          ),
          // Animated Circles (Decoration)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FuturisticTheme.neonCyan.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: FuturisticTheme.neonCyan.withOpacity(0.1),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Icon
                  Icon(Icons.psychology,
                      size: 80, color: FuturisticTheme.getAccentColor(isDark)),
                  const SizedBox(height: 20),
                  Text(
                    "POCKET AI",
                    style: FuturisticTheme.getHeaderStyle(isDark),
                  ),
                  const SizedBox(height: 40),

                  // Login Form Card
                  _buildGlassCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            style: FuturisticTheme.getBodyStyle(isDark),
                            decoration:
                                _buildInputDec("Email", Icons.email_outlined),
                            validator: (val) =>
                                val == null || !val.contains('@')
                                    ? 'Invalid Email'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            style: FuturisticTheme.getBodyStyle(isDark),
                            obscureText: true,
                            decoration:
                                _buildInputDec("Password", Icons.lock_outline),
                            validator: (val) => val == null || val.length < 6
                                ? 'Min 6 chars'
                                : null,
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FuturisticTheme.neonCyan,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.black)
                                  : Text(
                                      _isSignUp
                                          ? "INITIALIZE ACCOUNT"
                                          : "AUTHENTICATE",
                                      style: FuturisticTheme.buttonStyle
                                          .copyWith(
                                              fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Google Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: isDark ? Colors.white24 : Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Image.asset('assets/icon.png',
                          height: 24,
                          width: 24,
                          errorBuilder: (c, e, s) => Icon(Icons.login,
                              color: FuturisticTheme.getTextColor(isDark))),
                      label: Text(
                        "Sign in with Google",
                        style: FuturisticTheme.getBodyStyle(isDark),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Toggle Text
                  TextButton(
                    onPressed: () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp
                          ? "Already have access? Login"
                          : "New User? Create Access",
                      style: FuturisticTheme.monoStyle
                          .copyWith(color: FuturisticTheme.neonPurple),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: FuturisticTheme.getGlassDecoration(isDark),
      child: child,
    );
  }

  InputDecoration _buildInputDec(String label, IconData icon) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
          color: isDark ? FuturisticTheme.textGray : Colors.grey[700]),
      prefixIcon: Icon(icon, color: FuturisticTheme.textGray),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: FuturisticTheme.getAccentColor(isDark)),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
