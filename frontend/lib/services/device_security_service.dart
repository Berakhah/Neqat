import 'dart:io';
import 'package:root_check/root_check.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceSecurityService {
  /// Returns true if the device is rooted/jailbroken or running on an emulator.
  static Future<bool> isDeviceInsecure() async {
    bool isRooted = false;
    bool isEmulator = false;

    // Check for root/jailbreak
    try {
      // RootCheck.isRooted returns bool? (nullable bool)
      final rooted = await RootCheck.isRooted;
      isRooted = rooted ?? false; // treat null as not rooted (or use true for strict)
    } catch (_) {
      // If the check fails, err on the side of caution
      isRooted = true;
    }

    // Check for emulator
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        isEmulator = !(androidInfo.isPhysicalDevice ?? true);
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        isEmulator = !(iosInfo.isPhysicalDevice ?? true);
      }
    } catch (_) {
      // If the check fails, err on the side of caution
      isEmulator = true;
    }

    return isRooted || isEmulator;
  }
} 