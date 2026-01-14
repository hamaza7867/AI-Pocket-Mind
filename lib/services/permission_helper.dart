import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class PermissionHelper {
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      // Android 11 (API 30) and above
      if (androidInfo.version.sdkInt >= 30) {
        var status = await Permission.manageExternalStorage.status;
        if (status.isGranted) {
          return true;
        }
        status = await Permission.manageExternalStorage.request();
        return status.isGranted;
      }
      // Android 10 and below
      else {
        var status = await Permission.storage.status;
        if (status.isGranted) {
          return true;
        }
        status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return true; // Not Android
  }

  static Future<void> checkAndRequest() async {
    if (Platform.isAndroid) {
      await requestStoragePermission();
    }
  }
}
