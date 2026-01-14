import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';

class ContextService {
  final Battery _battery = Battery();

  Future<String> getTimeContext() async {
    final now = DateTime.now();
    return "Current Date/Time: ${now.toString()}";
  }

  Future<String> getLocationContext() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return "Location: Unknown (Service Disabled)";
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return "Location: Unknown (Permission Denied)";
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return "Location: Unknown (Permission Denied Forever)";
    }

    try {
      Position position = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 2), onTimeout: () {
        throw Exception("Location Timeout");
      });
      // In a real app, you'd use a Geocoding API here to get "New York, USA"
      // For now, we return coordinates.
      return "Location: Lat ${position.latitude.toStringAsFixed(4)}, Long ${position.longitude.toStringAsFixed(4)}";
    } catch (e) {
      return "Location: Unknown (Error: $e)";
    }
  }

  Future<String> getBatteryContext() async {
    try {
      final level = await _battery.batteryLevel;
      // WARNING: awaiting .onBatteryStateChanged.first BLOCKS until state CHANGES (plug/unplug).
      // We should NOT wait for a stream here.
      // For now, just return the level.
      return "Battery: $level%";
    } catch (e) {
      return "Battery: Unknown";
    }
  }

  Future<Map<String, String>> getAllContext() async {
    final time = await getTimeContext();
    final loc = await getLocationContext();
    final bat = await getBatteryContext();
    return {
      "time": time,
      "location": loc,
      "battery": bat,
    };
  }

  String formatContextForPrompt(Map<String, String> contextData) {
    return """
[SYSTEM CONTEXT]
${contextData['time']}
${contextData['location']}
${contextData['battery']}
[/SYSTEM CONTEXT]
    """;
  }
}
