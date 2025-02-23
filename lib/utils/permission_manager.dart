import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  static Future<bool> requestFullStorageAccessPermission({bool openAppSettingsIfDenied = true}) async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt >= 30) {
        // For Android 11 (SDK 30) and above, request manage external storage.
        return await requestPermission(Permission.manageExternalStorage, openAppSettingsIfDenied: openAppSettingsIfDenied);
      } else {
        // For legacy devices, request normal storage permission.
        return await requestPermission(Permission.storage, openAppSettingsIfDenied: openAppSettingsIfDenied);
      }
    }
    // For iOS and other platforms, assume the necessary access is granted.
    return true;
  }

  static Future<bool> requestPermissions(List<Permission> permissions) async {
    bool status = false;
    for (var permission in permissions) {
      status = status && await requestPermission(permission);
    }
    return status;
  }

  static Future<bool> requestPermission(Permission permission, {bool openAppSettingsIfDenied = true}) async {
    try {
      var status = await permission.request();  
      if (!status.isGranted) {
        debugPrint("$status - $permission [PermissionManager]");
        if(openAppSettingsIfDenied) {
          openAppSettings();
        }
      }
      return status.isGranted;
    } catch (e) {
      debugPrint("Error Requesting Permission - $permission [PermissionManager]");
    }
    return false;
  }
}