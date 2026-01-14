import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> get isBioLockEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('bioLock') ?? false;
  }

  Future<void> setBioLock(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bioLock', enabled);
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await auth.canCheckBiometrics || await auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      final available = await canCheckBiometrics();
      if (!available) return true; // Fallback: allow if no hardware

      return await auth.authenticate(
        localizedReason: 'Scan fingerprint to access your AI Pocket Mind',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly:
              true, // Force generic auth if needed, but let's prefer bio
        ),
      );
    } catch (e) {
      print("Auth Error: $e");
      return false;
    }
  }
}
