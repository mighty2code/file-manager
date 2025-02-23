import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class FileUtils {
  static bool isApkFile(File file) {
    // Extract the file extension and convert it to lowercase
    final ext = p.extension(file.path).toLowerCase();
    // Check if it's an APK file (Android application package)
    return ext == '.apk';
  }

  Future<void> copyFileWithMetadata(
      {required File source, required File destination}) async {
    try {
      if (await source.exists()) {
        // Copy the content of the file to the destination
        await source.copy(destination.path);
        // Get file metadata from the source file
        var sourceStat = await source.stat();
        // Preserve the last modified time
        await destination.setLastModified(sourceStat.modified);
        debugPrint('File copied with metadata (last modified) preserved!');
      } else {
        debugPrint('Source file does not exist.');
      }
    } catch (e) {
      debugPrint('Error occurred while copying file: $e');
    }
  }
}
