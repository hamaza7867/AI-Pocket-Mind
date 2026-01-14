import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_utils.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: FuturisticTheme.getBackgroundColor(isDark),
      body: Container(
        decoration: BoxDecoration(
          gradient: FuturisticTheme.getBackgroundGradient(isDark),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'SKIP',
                    style: TextStyle(
                      color: FuturisticTheme.neonCyan,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Page view
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                  children: [
                    _buildPage1(isDark),
                    _buildPage2(isDark),
                    _buildPage3(isDark),
                  ],
                ),
              ),

              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? FuturisticTheme.neonCyan
                          : Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Next/Get Started button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FuturisticTheme.neonCyan,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentPage == 2 ? 'GET STARTED' : 'NEXT',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage1(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: FuturisticTheme.neonCyan.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: FuturisticTheme.neonCyan,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              size: 60,
              color: FuturisticTheme.neonCyan,
            ),
          ),

          const SizedBox(height: 40),

          Text(
            'Desktop Bridge',
            style: FuturisticTheme.getHeaderStyle(isDark).copyWith(
              fontSize: 32,
              color: FuturisticTheme.neonCyan,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'Run powerful AI on your PC, control from your phone',
            style: FuturisticTheme.getBodyStyle(isDark).copyWith(
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: FuturisticTheme.getGlassDecoration(isDark),
            child: Column(
              children: [
                _buildFeatureRow(
                  Icons.computer,
                  'Run Ollama on your PC',
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildFeatureRow(
                  Icons.smartphone,
                  'Scan QR code to connect',
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildFeatureRow(
                  Icons.lock,
                  'All data stays on your network',
                  isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage2(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: FuturisticTheme.neonPurple.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: FuturisticTheme.neonPurple,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.people,
              size: 60,
              color: FuturisticTheme.neonPurple,
            ),
          ),

          const SizedBox(height: 40),

          Text(
            'AI Personas',
            style: FuturisticTheme.getHeaderStyle(isDark).copyWith(
              fontSize: 32,
              color: FuturisticTheme.neonPurple,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'Switch between different AI personalities instantly',
            style: FuturisticTheme.getBodyStyle(isDark).copyWith(
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: FuturisticTheme.getGlassDecoration(isDark),
            child: Column(
              children: [
                _buildFeatureRow(
                  Icons.work,
                  'Professional Assistant',
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildFeatureRow(
                  Icons.school,
                  'Study Tutor',
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildFeatureRow(
                  Icons.code,
                  'Coding Expert',
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildFeatureRow(
                  Icons.add_circle_outline,
                  'Create unlimited custom personas',
                  isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage3(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: FuturisticTheme.neonBlue.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: FuturisticTheme.neonBlue,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.record_voice_over,
              size: 60,
              color: FuturisticTheme.neonBlue,
            ),
          ),

          const SizedBox(height: 40),

          Text(
            'Voice Mode',
            style: FuturisticTheme.getHeaderStyle(isDark).copyWith(
              fontSize: 32,
              color: FuturisticTheme.neonBlue,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'Talk to your AI assistant hands-free',
            style: FuturisticTheme.getBodyStyle(isDark).copyWith(
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: FuturisticTheme.getGlassDecoration(isDark),
            child: Column(
              children: [
                _buildFeatureRow(
                  Icons.mic,
                  'Speak your questions',
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildFeatureRow(
                  Icons.volume_up,
                  'Listen to AI responses',
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildFeatureRow(
                  Icons.loop,
                  'Live Mode for continuous conversation',
                  isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'Ready to experience the future of AI?',
            style: FuturisticTheme.getTitleStyle(isDark).copyWith(
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: FuturisticTheme.neonCyan),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: FuturisticTheme.getBodyStyle(isDark).copyWith(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
