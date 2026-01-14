import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/chat_provider.dart';
import 'providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/wizard_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/server_dashboard.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'services/app_config.dart';
import 'screens/login_screen.dart';
import 'utils/theme_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await SupabaseService().initialize(
    AppConfig.supabaseUrl,
    AppConfig.supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'PocketAI',
          theme: themeProvider.isDarkMode
              ? AppTheme.darkTheme
              : AppTheme.lightTheme,
          home: Platform.isWindows
              ? const ServerDashboard()
              : FutureBuilder<bool>(
                  future: _checkOnboarding(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient:
                              FuturisticTheme.getBackgroundGradient(false),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: FuturisticTheme.neonCyan,
                          ),
                        ),
                      );
                    }
                    final onboardingComplete = snapshot.data ?? false;
                    return onboardingComplete
                        ? const StartupLogic()
                        : const OnboardingScreen();
                  },
                ),
          routes: {
            '/home': (context) => const StartupLogic(),
          },
        );
      },
    );
  }

  Future<bool> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }
}

class StartupLogic extends StatefulWidget {
  const StartupLogic({super.key});

  @override
  State<StartupLogic> createState() => _StartupLogicState();
}

class _StartupLogicState extends State<StartupLogic> {
  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {
    try {
      await [
        Permission.storage,
        Permission.manageExternalStorage,
      ].request();

      final authService = AuthService();
      if (await authService.isBioLockEnabled) {
        bool authenticated = await authService.authenticate();
        if (!authenticated) {
          if (mounted) {}
          return;
        }
      }

      bool isFirstRun = await Future.any([
        _loadPrefs(),
        Future.delayed(const Duration(seconds: 3), () => true),
      ]);

      if (mounted) {
        _navigate(isFirstRun);
      }
    } catch (e) {
      if (mounted) _navigate(true);
    }
  }

  Future<bool> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isFirstRun') ?? true;
  }

  void _navigate(bool isFirstRun) {
    if (isFirstRun) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WizardScreen()));
      return;
    }

    final user = SupabaseService().client.auth.currentUser;
    if (user != null) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ChatScreen()));
    } else {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF2C3E50),
      body: Center(
        child: Icon(Icons.psychology, size: 80, color: Colors.white),
      ),
    );
  }
}
