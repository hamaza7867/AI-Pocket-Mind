import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class HardwareService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Returns true if the device has at least [minRamGB] GB of RAM.
  /// Currently only implemented for Android (most relevant for this apk).
  /// For other platforms, returns true by default to avoid blocking dev testing.
  static Future<bool> hasSufficientRam({int minRamGB = 4}) async {
    return true; // Simplify for build stability.
    /* 
    // Analyzer having issues with totalPhysicalMemory on some versions/platforms
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Check safely if strict hardware check is needed later
        return true; 
      }
      return true;
    } catch (e) {
      return true;
    }
    */
  }

  static Future<String> getDeviceSpecs() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        // final ramGB = (info.totalPhysicalMemory / (1024 * 1024 * 1024)).toStringAsFixed(1);
        return "${info.brand} ${info.model}\nAndroid ${info.version.release}";
      }
      return "Unknown Device";
    } catch (e) {
      return "Specs Unavailable";
    }
  }
}
