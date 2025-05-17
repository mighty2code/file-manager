import 'package:file_manager/constants/constants.dart';
import 'package:file_manager/constants/native_config.dart';
import 'package:file_manager/data/local/shared_prefs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

class SDCardFileUtils {
  static const _channel = MethodChannel(NativeChannels.android);
  
  /// Creates a file with the given name in the destination.
  /// [destination] should be either a normal file system path or a content URI.
  static Future<String?> createFile({
    required String name,
    required String destination,
    String mimeType = "text/plain"
  }) async {
    // SD card (SAF) operation via native code.
    try {
      final String? uri = await _channel.invokeMethod(AndroidMethods.sdcardCreateFile, {
        "base-uri": SharedPrefs.getString(SharedPrefKeys.sdcardUri),
        "destination": destination,
        "name": name,
        "mimeType": mimeType,
      });
      return uri; // returns the new file’s content URI
    } on PlatformException catch (e) {
      debugPrint("Error creating SD card file: ${e.message}");
      return null;
    }
  }

  /// Creates a directory with the given name in the destination.
  static Future<String?> createDirectory({
    required String name,
    required String destination,
  }) async {
      try {
        final String? uri = await _channel.invokeMethod(AndroidMethods.sdcardCreateDirectory, {
          "base-uri": SharedPrefs.getString(SharedPrefKeys.sdcardUri),
          "destination": destination,
          "name": name,
        });
        return uri;
      } on PlatformException catch (e) {
        debugPrint("Error creating SD card directory: ${e.message}");
        return null;
      }
    
  }

  /// Clones a file from source to destination.
  /// [source] and [destination] are expected to be either file paths or content URIs.
  static Future<bool> cloneFile({
    required String source,
    required String destination,
  }) async {
      try {
        final bool success = await _channel.invokeMethod(AndroidMethods.sdcardCloneFile, {
          "base-uri": SharedPrefs.getString(SharedPrefKeys.sdcardUri),
          "source": source,
          "destination": destination,
        });
        return success;
      } on PlatformException catch (e) {
        debugPrint("Error cloning SD card file: ${e.message}");
        return false;
      }
  }

  /// Clones a directory from source to destination.
  /// [source] and [destination] are expected to be either directory paths or content URIs.
  static Future<bool> cloneDirectory({
    required String source,
    required String destination,
  }) async {
      try {
        final bool success = await _channel.invokeMethod(AndroidMethods.sdcardCloneDirectory, {
          "base-uri": SharedPrefs.getString(SharedPrefKeys.sdcardUri),
          "source": source,
          "destination": destination,
        });
        return success;
      } on PlatformException catch (e) {
        debugPrint("Error cloning SD card directory: ${e.message}");
        return false;
      }
  }
}