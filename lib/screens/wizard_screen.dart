import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';
import '../utils/theme_utils.dart';
import '../providers/theme_provider.dart'; // Added
import 'dart:ui';

class WizardScreen extends StatefulWidget {
  const WizardScreen({super.key});

  @override
  State<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen> {
  final PageController _pageController = PageController();

  Future<void> _finishWizard(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstRun', false);

    if (!mounted) return;

    // Default to Cloud Mode for best Agentic experience
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.updateSettings(
      desktopBridgeUrl: chatProvider.currentDesktopUrl,
      apiKey: chatProvider.currentApiKey,
      mode: AIMode.byoapi,
      cloudProvider: "OpenAI",
      cloudModel: "gpt-3.5-turbo",
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      backgroundColor: FuturisticTheme.getBackgroundColor(isDark),
      body: Stack(
        children: [
          // Background Effects
          Positioned.fill(
            child: Container(
              child: Container(
                decoration: BoxDecoration(
                  gradient: FuturisticTheme.getBackgroundGradient(isDark),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildGlassCard(
                      child: const Icon(Icons.psychology,
                          size: 80, color: FuturisticTheme.neonPurple)),
                  const SizedBox(height: 40),
                  Text(
                    "INITIATING\nPOCKET MIND",
                    textAlign: TextAlign.center,
                    style: FuturisticTheme.getHeaderStyle(isDark).copyWith(
                      fontSize: 32,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Your Advanced Neural Interface.\n\nNow enhanced with Real-Time Web Access\nand Autonomous Agent capabilities.",
                    textAlign: TextAlign.center,
                    style: FuturisticTheme.getBodyStyle(isDark).copyWith(
                      fontSize: 16,
                      color: FuturisticTheme.textGray,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  _buildNeonButton(
                    text: "INITIALIZE SYSTEM",
                    onPressed: () => _finishWizard(context),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: FuturisticTheme.getGlassDecoration(
          Provider.of<ThemeProvider>(context).isDarkMode),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }

  Widget _buildNeonButton(
      {required String text, required VoidCallback onPressed, Color? color}) {
    final btnColor = color ?? FuturisticTheme.neonCyan;
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: btnColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: FuturisticTheme.buttonStyle
              .copyWith(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
